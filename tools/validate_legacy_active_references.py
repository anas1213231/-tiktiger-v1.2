#!/usr/bin/env python3
"""Fail-closed audit for active Tiktiger Xcode inputs.

The audit intentionally ignores Markdown documentation and Git history. Historical
references may remain in reports, but they must never enter active build inputs.
"""
from collections import Counter
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
HOST_ROOT = ROOT / "Tiktiger_1.1" / "TiktigerHost"
HOST_PROJECT = HOST_ROOT / "TiktigerHost.xcodeproj"
HOST_PBX_PATH = HOST_PROJECT / "project.pbxproj"
DYLIB_PROJECT = ROOT / "Tiktiger_1.1" / "Xcode_Dylib_Project" / "TiktigerDylib.xcodeproj"
DYLIB_PBX_PATH = DYLIB_PROJECT / "project.pbxproj"
WORKFLOW = ROOT / ".github" / "workflows" / "build-tiktiger-ios.yml"

LEGACY = re.compile(r"TigerIOSStarter|FeatureKit|VibeTok")
SOURCE_SUFFIXES = {
    ".swift", ".m", ".mm", ".c", ".cc", ".cpp", ".h", ".hh", ".hpp",
    ".plist", ".entitlements", ".json", ".xcconfig", ".sh",
}

errors: list[str] = []

def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)

def read_bytes(path: Path) -> bytes:
    require(path.is_file(), f"missing required file: {path.relative_to(ROOT)}")
    return path.read_bytes() if path.is_file() else b""

def scan_active_file(path: Path) -> None:
    data = read_bytes(path)
    if not data:
        return
    text = data.decode("utf-8", errors="ignore")
    match = LEGACY.search(text)
    if match is not None:
        errors.append(f"legacy active reference {match.group(0)!r}: {path.relative_to(ROOT)}")

def pbx_ids(path: Path) -> tuple[set[str], Counter[str], str]:
    text = path.read_text(encoding="utf-8")
    declared = re.findall(r"^\s*([A-Fa-f0-9]{24})\s+/\*.*?\*/\s*=\s*\{", text, re.MULTILINE)
    root_group_id = "A10000000000000000000060" if "TiktigerDylib.xcodeproj" in str(path) else "100000000000000000000060"
    if re.search(rf"^\s*{root_group_id}\s*=\s*\{{", text, re.MULTILINE):
        declared.append(root_group_id)
    counts = Counter(declared)
    all_ids = set(re.findall(r"\b[A-Fa-f0-9]{24}\b", text))
    unknown = all_ids - set(declared)
    require(not [key for key, count in counts.items() if count > 1], f"duplicate PBX UUIDs in {path.relative_to(ROOT)}")
    require(not unknown, f"unresolved PBX UUID references in {path.relative_to(ROOT)}: {sorted(unknown)}")
    return set(declared), counts, text

# These are the only active text/binary inputs that can affect the current build.
active_files: set[Path] = {
    HOST_PBX_PATH,
    DYLIB_PBX_PATH,
    WORKFLOW,
    HOST_PROJECT / "xcshareddata/xcschemes/TiktigerHost.xcscheme",
    HOST_PROJECT / "xcshareddata/xcschemes/TigerCore.xcscheme",
    DYLIB_PROJECT / "xcshareddata/xcschemes/TiktigerDylib.xcscheme",
}
for tree in (HOST_ROOT, ROOT / "Tiktiger_1.1" / "Xcode_Dylib_Project"):
    for path in tree.rglob("*"):
        if not path.is_file() or "Build" in path.parts or ".DerivedData" in path.parts:
            continue
        if path.suffix.lower() in SOURCE_SUFFIXES:
            active_files.add(path)
        if "Resources" in path.parts or "Assets.xcassets" in path.parts:
            active_files.add(path)

for path in sorted(active_files):
    scan_active_file(path)

# No legacy-named file or directory may remain in the deliverable source tree.
for path in ROOT.rglob("*"):
    if ".git" in path.parts or "Build" in path.parts or ".DerivedData" in path.parts:
        continue
    require(not LEGACY.search(path.name), f"legacy-named active path: {path.relative_to(ROOT)}")

host_ids, _, host_pbx = pbx_ids(HOST_PBX_PATH)
dylib_ids, _, dylib_pbx = pbx_ids(DYLIB_PBX_PATH)

require("name = TiktigerHost;" in host_pbx, "active Host target is not TiktigerHost")
require("productName = TiktigerHost;" in host_pbx, "active Host productName is not TiktigerHost")
require("path = TiktigerHost.app;" in host_pbx, "active Host product is not TiktigerHost.app")
require("TiktigerHostApp.swift in Sources" in host_pbx, "renamed App entry point is not in Compile Sources")
require((HOST_ROOT / "TigerHost" / "TiktigerHostApp.swift").is_file(), "missing TiktigerHostApp.swift source")
require((HOST_ROOT / "TigerHost" / "TigerHost.entitlements").is_file(), "missing Host entitlements")
require("CODE_SIGN_ENTITLEMENTS = TigerHost/TigerHost.entitlements;" in host_pbx, "entitlements path is broken")
require("Tiktiger.dylib in Embed Tiktiger" in host_pbx, "Tiktiger.dylib is not in the Host embed phase")
require("platformFilters = (iphoneos, );" in host_pbx, "device-only dylib embed guard is missing")
require("CodeSignOnCopy" in host_pbx, "dylib embed lacks CodeSignOnCopy")
require("TiktigerFeatures.c in Sources" in dylib_pbx, "feature source is not in dylib Compile Sources")
require("TiktigerRuntime.c in Sources" in dylib_pbx, "runtime source is not in dylib Compile Sources")

scheme_expectations = {
    HOST_PROJECT / "xcshareddata/xcschemes/TiktigerHost.xcscheme": ("TiktigerHost", "TiktigerHost.app", "100000000000000000000042"),
    HOST_PROJECT / "xcshareddata/xcschemes/TigerCore.xcscheme": ("TigerCore", "TigerCore.framework", "100000000000000000000041"),
    DYLIB_PROJECT / "xcshareddata/xcschemes/TiktigerDylib.xcscheme": ("TiktigerDylib", "Tiktiger.dylib", "A10000000000000000000041"),
}
for scheme_path, (target_name, product_name, blueprint_id) in scheme_expectations.items():
    try:
        root = ET.parse(scheme_path).getroot()
    except (FileNotFoundError, ET.ParseError) as exc:
        errors.append(f"invalid scheme {scheme_path.relative_to(ROOT)}: {exc}")
        continue
    refs = root.findall(".//BuildableReference")
    require(bool(refs), f"scheme has no BuildableReference: {scheme_path.relative_to(ROOT)}")
    for ref in refs:
        require(ref.attrib.get("ReferencedContainer") in {"container:TiktigerHost.xcodeproj", "container:TiktigerDylib.xcodeproj"}, f"broken scheme container in {scheme_path.relative_to(ROOT)}")
        require(ref.attrib.get("BlueprintIdentifier") == blueprint_id, f"wrong BlueprintIdentifier in {scheme_path.relative_to(ROOT)}")
        require(ref.attrib.get("BlueprintName") == target_name, f"wrong BlueprintName in {scheme_path.relative_to(ROOT)}")
        require(ref.attrib.get("BuildableName") == product_name, f"wrong BuildableName in {scheme_path.relative_to(ROOT)}")
    if "TiktigerHost" in target_name:
        require("ReferencedContainer=\"container:TiktigerHost.xcodeproj\"" in scheme_path.read_text(encoding="utf-8"), f"Host scheme container is not renamed: {scheme_path.relative_to(ROOT)}")

require("Tiktiger_1.1/TiktigerHost" in WORKFLOW.read_text(encoding="utf-8"), "Workflow does not use TiktigerHost path")
require("TiktigerHost.xcodeproj" in WORKFLOW.read_text(encoding="utf-8"), "Workflow does not use TiktigerHost.xcodeproj")

if errors:
    print("legacy_active_reference_guard: FAIL")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("legacy_active_reference_guard: PASS")
print("active Host project: TiktigerHost.xcodeproj")
print("active Host target: TiktigerHost")
print("active Host scheme: TiktigerHost.xcscheme")
print("legacy active references: 0")
print("broken PBX references: 0")
print("duplicate UUIDs: 0")
print("old UI in build: NO")
print("old assets in build: NO")
