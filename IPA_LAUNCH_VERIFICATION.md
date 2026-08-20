# Tiktiger 1.1 — IPA Launch Verification

## Scope and evidence

تم تدقيق IPA unsigned الحالية ثم إنشاء `TiktigerHost_SIGNING_FIXED_unsigned.ipa` من نفس Payload بعد نجاح GitHub Actions run `32389935401`. هذا التدقيق يثبت بنية IPA وMach-O وInfo.plist وruntime paths قبل eSign. لا يمكن حسم صحة شهادة المالك أو Provisioning Profile أو سبب crash على iPhone بدون IPA الموقعة فعليًا أو crash/device log منها.

## Requested fields

| Field | Result |
|---|---|
| IPA STRUCTURE | **PASS** — one `Payload/TiktigerHost.app` with one Host executable and one copy of each nested binary |
| HOST MACH-O | Mach-O 64-bit arm64 executable |
| HOST ARCH | **arm64** |
| DYLIB MACH-O | Mach-O 64-bit arm64 dynamically linked shared library, `mh_dylib` |
| DYLIB ARCH | **arm64** |
| DYLIB INSTALL NAME | **`@rpath/Tiktiger.dylib`** |
| TIGERCORE MACH-O | Mach-O 64-bit arm64 dynamically linked shared library, `mh_dylib` |
| TIGERCORE ARCH | **arm64** |
| TIGERCORE INSTALL NAME | **`@rpath/TigerCore.framework/TigerCore`** |
| HOST RPATH | **`@executable_path/Frameworks`** |
| BUNDLE ID | **`com.ucorc.Tiktiger`** |
| CORE BUNDLE ID | **`com.ucorc.TiktigerCore`** |
| CFBundleExecutable | `TiktigerHost` |
| CFBundlePackageType | `APPL` |
| MinimumOSVersion | `15.0` |
| UIDeviceFamily | `[1, 2]` |
| Photos Usage Description | **PRESENT** |
| Face ID Usage Description | **PRESENT** |
| ENTITLEMENTS REQUIRED | None in project entitlement file; Photos/Face ID are Info.plist usage descriptions |
| SIGNING STATE OF AUDITED IPA | **UNSIGNED** by design; no `_CodeSignature` or `embedded.mobileprovision` |
| SIGNED IPA STATE | **NOT AVAILABLE** — owner eSign output is required for signed verification |
| SIGNING_FIXED IPA | `TiktigerHost_SIGNING_FIXED_unsigned.ipa` |
| SIGNING_FIXED IPA SHA-256 | `7a3fbd34742ff708c711293c85f60be351183809b95ec0f35ed8c59ee257cdbe` |

## IPA structure

```text
Payload/TiktigerHost.app/TiktigerHost
Payload/TiktigerHost.app/Frameworks/Tiktiger.dylib
Payload/TiktigerHost.app/Frameworks/TigerCore.framework/TigerCore
Payload/TiktigerHost.app/Info.plist
```

The audit found no duplicated `Tiktiger.dylib`, no duplicated `TigerCore.framework`, no old framework copy, and no provisioning/signature marker in the unsigned input. The embedded approved dylib SHA-256 is:

```text
c74d63937efdb58421382910e0de0c5cd23dd8ee046c986f8f4698e678a31c80
```

## Dependencies and dynamic loader

The Host executable has the required nested dependency:

```text
@rpath/TigerCore.framework/TigerCore
```

The Host does not list `Tiktiger.dylib` as a static `LC_LOAD_DYLIB` dependency because `TiktigerRuntimeCoordinator` intentionally loads it with `dlopen`. Its expected runtime path is:

```text
Payload/TiktigerHost.app/Frameworks/Tiktiger.dylib
```

System framework paths such as `/System/Library/Frameworks/...` and `/usr/lib/...` are normal iOS system dependencies. The audit found no `DerivedData`, `/Users/`, or `/Applications/` project path in the embedded app dependency list. The previous TigerCore absolute install-name issue was fixed in the binary verified by run `32389935401`.

## Signing hierarchy

The current IPA is intentionally unsigned. After eSign, the required order is:

1. Sign `Frameworks/TigerCore.framework/TigerCore`.
2. Sign `Frameworks/Tiktiger.dylib`.
3. Sign the main `TiktigerHost` executable and app bundle last.
4. Verify every nested component and the app bundle with strict code-signature verification.
5. Confirm the profile’s App ID allows `com.ucorc.Tiktiger` and that the nested Core bundle remains `com.ucorc.TiktigerCore`.

`CodeSignOnCopy` in an Xcode build is not sufficient proof for a post-eSign IPA. The supplied `tools/verify_signed_ipa.py` classifies each artifact as `SIGNED`, `UNSIGNED`, or `INVALID`; it must be run on macOS for full `codesign`, `lipo`, and `otool` output.

## Potential launch crashes

| Potential cause | Current audit result | Interpretation |
|---|---|---|
| Missing or invalid code signature | Expected in unsigned IPA | Owner eSign must sign nested binaries and app consistently. |
| Missing or mismatched provisioning profile | Cannot be assessed before eSign | Profile must permit exact Host Bundle ID. |
| Absolute TigerCore install name | **FIXED** | Final embedded binary is `@rpath/TigerCore.framework/TigerCore`. |
| Missing Host RPATH | **NOT FOUND** | Host contains `@executable_path/Frameworks`. |
| Missing `Tiktiger.dylib` | **NOT FOUND** | One arm64 binary exists at the required Frameworks path. |
| Wrong architecture | **NOT FOUND** in audited arm64 IPA | `file` reports arm64 for all three Mach-O candidates. |
| Device dylib `dlopen` failure | Runtime-dependent | Host records `dlerror` and opens Diagnostics instead of calling a NULL symbol. |
| Missing `dlsym` symbol | Runtime-dependent | Host records `FAILED` and avoids NULL function invocation. |
| eSign changed Bundle ID or nested identifiers | Unknown until signed IPA | Run verifier on the eSign output before installation. |

## Diagnostic Launch review

`TiktigerRuntimeCoordinator` is fail-closed and non-crashing for loader failures. It retains the `dlopen` handle, records each candidate path and `dlerror`, records every `dlsym` as `FOUND/FAILED`, checks symbols before `unsafeBitCast` invocation, and returns from `start()` when the dylib cannot load. The simulator guard skips device dylib loading without terminating the Host. No `fatalError`, force unwrap, or intentional `assert` crash path was found in the reviewed coordinator.

Therefore a true iPhone launch crash before UI is more likely to be caused by eSign signing/provisioning/nested-code handling or a binary/runtime loader error outside the unsigned IPA audit. The signed artifact and device log are required to distinguish these cases.

## Fixes applied for this audit

| Fix | Scope | Result |
|---|---|---|
| TigerCore install name | Host PBX/build path only | `@rpath/TigerCore.framework/TigerCore` |
| Simulator crash diagnostics | Workflow only | Captures dyld/crash report and stdout smoke report |
| Signed IPA verifier | `tools/verify_signed_ipa.py` | Reports signed/unsigned/invalid, nested components, profile note, IDs and Mach-O tool output |
| New distribution package | Packaging only | `TiktigerHost_SIGNING_FIXED_unsigned.ipa` |
| Features/UI/Architecture | Not changed in this audit | Preserved |
| Tiktiger.dylib | Not changed or replaced | SHA-256 preserved |

## Current launch status

| Stage | Status |
|---|---|
| SIGNING_FIXED unsigned IPA structure | **PASS** |
| Unsigned IPA structure | **PASS** |
| Simulator signing | **PASS** in CI smoke |
| Simulator install | **PASS** in CI smoke |
| Simulator launch | **PASS** in CI smoke after TigerCore rpath fix |
| Owner eSign signing | **PENDING** |
| Real iPhone installation | **PENDING** |
| Real iPhone Host UI visible | **NOT VERIFIED** |
| Real device runtime milestones | **NOT VERIFIED** |

## Required remaining device step

Sign `TiktigerHost_SIGNING_FIXED_unsigned.ipa` in eSign using the owner’s authorized certificate and a provisioning profile that permits `com.ucorc.Tiktiger`. Keep recursive nested signing enabled, do not add entitlements, install the result on the authorized iPhone, and if it fails collect the device crash/console output containing `dyld`, `Tiktiger`, `TigerCore`, `Code Signature`, `Termination Reason`, `Exception Type`, or `Library not loaded`. Then run `tools/verify_signed_ipa.py` on macOS against the signed IPA and send its JSON plus the device log.

Do not send Apple ID passwords, 2FA codes, private keys, or certificate passwords in chat.

## References

[1]: tools/verify_signed_ipa.py
[2]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerRuntimeCoordinator.swift
[3]: Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj/project.pbxproj
[4]: ESIGN_SIGNING_GUIDE.md
[5]: .github/workflows/build-tiktiger-ios.yml

الأدلة الداخلية هي [1]–[5]، أما الدليل التنفيذي للمكتبات وBuild فهو artifact run `32389935401`.
