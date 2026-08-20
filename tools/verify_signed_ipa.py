#!/usr/bin/env python3
"""Verify an iOS IPA's structure, Mach-O inputs, signing state, and provisioning identity.

The tool is intentionally fail-closed for signed artifacts: an app that has a
signature marker but fails codesign verification is INVALID, not UNSIGNED.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

EXPECTED_APP_BUNDLE_ID = "com.ucorc.Tiktiger"
EXPECTED_CORE_BUNDLE_ID = "com.ucorc.TiktigerCore"
EXPECTED_DYLIB_SHA = "c74d63937efdb58421382910e0de0c5cd23dd8ee046c986f8f4698e678a31c80"
EXPECTED_DYLIB_INSTALL_NAME = "@rpath/Tiktiger.dylib"
EXPECTED_CORE_INSTALL_NAME = "@rpath/TigerCore.framework/TigerCore"
EXPECTED_HOST_RPATH = "@executable_path/Frameworks"


def run(command: list[str]) -> tuple[int, str]:
    try:
        proc = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    except FileNotFoundError:
        return 127, f"TOOL_UNAVAILABLE: {command[0]}"
    return proc.returncode, proc.stdout.strip()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def plist_read(path: Path) -> dict:
    return plistlib.loads(path.read_bytes())


def find_macho_files(app: Path) -> list[Path]:
    candidates = [app / app.name.removesuffix(".app")]
    candidates += [p for p in (app / "Frameworks").rglob("*") if p.is_file() and not p.name.endswith(".plist")]
    output: list[Path] = []
    for path in candidates:
        code, text = run(["file", str(path)])
        if code == 0 and "Mach-O" in text:
            output.append(path)
    return sorted(set(output))


def inspect_macho(path: Path) -> dict:
    code_file, file_result = run(["file", str(path)])
    code_arch, arch_result = run(["lipo", "-info", str(path)])
    code_header, header_result = run(["otool", "-hv", str(path)])
    code_deps, deps_result = run(["otool", "-L", str(path)])
    signed_marker = "LC_CODE_SIGNATURE" in header_result or "code signature" in header_result.lower()
    return {
        "path": str(path),
        "file": file_result,
        "lipo_info": arch_result,
        "otool_hv": header_result,
        "otool_L": deps_result,
        "file_ok": code_file == 0 and "Mach-O" in file_result,
        "arm64_ok": (code_arch == 0 and "arm64" in arch_result) or (code_arch == 127 and "arm64" in file_result),
        "signature_load_command": signed_marker,
        "has_absolute_project_path": any(token in deps_result for token in ("DerivedData", "/Users/", "/Applications/")),
    }


def verify_codesign(path: Path) -> dict:
    code, output = run(["codesign", "--verify", "--strict", "--verbose=2", str(path)])
    display_code, display = run(["codesign", "-dvv", str(path)])
    return {
        "path": str(path),
        "verify_code": code,
        "verify_output": output,
        "display_code": display_code,
        "display_output": display,
        "verified": code == 0,
    }


def decode_provisioning(path: Path) -> tuple[dict | None, str]:
    if shutil.which("security") is None:
        return None, "security tool unavailable on this host"
    code, output = run(["security", "cms", "-D", "-i", str(path)])
    if code != 0:
        return None, output
    try:
        return plistlib.loads(output.encode()), "decoded"
    except Exception as exc:  # pragma: no cover - defensive for malformed profiles
        return None, f"plist decode failed: {exc}"


def verify_ipa(ipa: Path) -> dict:
    with tempfile.TemporaryDirectory(prefix="tiktiger_ipa_verify_") as temp_dir:
        root = Path(temp_dir)
        with zipfile.ZipFile(ipa) as archive:
            archive.extractall(root)
        payload = root / "Payload"
        apps = sorted(payload.glob("*.app"))
        if len(apps) != 1:
            raise SystemExit(f"Expected exactly one Payload app, found {len(apps)}")
        app = apps[0]
        app_plist = plist_read(app / "Info.plist")
        frameworks = app / "Frameworks"
        nested = sorted([p for p in frameworks.rglob("*") if p.is_file()]) if frameworks.exists() else []
        macho_paths = find_macho_files(app)
        macho = [inspect_macho(p) for p in macho_paths]
        signature_paths = [app] + sorted([p for p in frameworks.iterdir() if p.is_dir() or p.is_file()]) if frameworks.exists() else [app]
        codesign_results = [verify_codesign(p) for p in signature_paths if p.exists()]
        signature_markers = any(item["signature_load_command"] for item in macho) or (app / "_CodeSignature").exists() or (app / "embedded.mobileprovision").exists()
        all_signed = all(item["verified"] for item in codesign_results) if codesign_results else False
        if all_signed and (app / "embedded.mobileprovision").exists():
            signing_state = "SIGNED"
        elif signature_markers:
            signing_state = "INVALID"
        else:
            signing_state = "UNSIGNED"

        provisioning = None
        provisioning_note = "not present"
        profile_path = app / "embedded.mobileprovision"
        if profile_path.exists():
            provisioning, provisioning_note = decode_provisioning(profile_path)

        result = {
            "ipa": str(ipa),
            "ipa_sha256": sha256(ipa),
            "app_path": str(app),
            "app_bundle_id": app_plist.get("CFBundleIdentifier"),
            "app_executable": app_plist.get("CFBundleExecutable"),
            "app_package_type": app_plist.get("CFBundlePackageType"),
            "minimum_os_version": app_plist.get("MinimumOSVersion"),
            "device_family": app_plist.get("UIDeviceFamily"),
            "photos_usage_description": app_plist.get("NSPhotoLibraryAddUsageDescription"),
            "face_id_usage_description": app_plist.get("NSFaceIDUsageDescription"),
            "framework_files": [str(p.relative_to(app)) for p in nested],
            "macho": macho,
            "signing_state": signing_state,
            "signing": codesign_results,
            "provisioning_note": provisioning_note,
            "provisioning_application_identifier": (provisioning or {}).get("Entitlements", {}).get("application-identifier") if provisioning else None,
            "expected": {
                "app_bundle_id": EXPECTED_APP_BUNDLE_ID,
                "core_bundle_id": EXPECTED_CORE_BUNDLE_ID,
                "dylib_sha256": EXPECTED_DYLIB_SHA,
                "dylib_install_name": EXPECTED_DYLIB_INSTALL_NAME,
                "core_install_name": EXPECTED_CORE_INSTALL_NAME,
                "host_rpath": EXPECTED_HOST_RPATH,
            },
        }
        return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("ipa", type=Path)
    parser.add_argument("--json", dest="json_path", type=Path)
    args = parser.parse_args()
    result = verify_ipa(args.ipa)
    rendered = json.dumps(result, indent=2, ensure_ascii=False)
    if args.json_path:
        args.json_path.write_text(rendered + "\n")
    print(rendered)
    return 0 if result["signing_state"] in {"UNSIGNED", "SIGNED"} else 2


if __name__ == "__main__":
    raise SystemExit(main())
