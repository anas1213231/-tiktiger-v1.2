# Tiktiger 1.1 — Runtime Verification

هذا التقرير يفصل بين **Xcode/Simulator evidence** وبين **Real Device Runtime evidence**. نجاح Build أو وجود dylib داخل IPA لا يثبت تحميلها وتشغيلها على جهاز حقيقي. لا تصبح `ui_presented` حالة `VERIFIED` إلا بعد Host view-hierarchy confirmation محفوظة في تقرير iPhone.

## Build evidence

| Item | Result |
|---|---|
| GitHub Actions run | `32389935401` |
| Commit | `18d30a03f5b3cbe220c6cc8896c30beca8c78ab6` |
| Xcode runner | macOS/Xcode workflow؛ تفاصيل toolchain في `verification.txt` |
| dylib build | **BUILD SUCCEEDED** |
| dylib binary | Mach-O 64-bit dynamically linked shared library, arm64 |
| dylib SHA-256 | `c74d63937efdb58421382910e0de0c5cd23dd8ee046c986f8f4698e678a31c80` |
| Host iphoneos build | **BUILD SUCCEEDED** |
| Host dylib embedding | **EMBED SUCCEEDED** |
| Host iphonesimulator build | **BUILD SUCCEEDED** |
| Simulator signing/install/launch/screenshot | **SUCCEEDED** |
| Xcode verified | **YES — actual BUILD SUCCEEDED evidence present** |

## Runtime ownership model

يملك constructor في `TiktigerRuntime.c` milestones الخاصة بـ`dylib_loaded`, `initializer_executed`, `core_started`, و`feature_registry_ready` فقط. لا يكتب constructor إلى `g_ui_registered` أو `g_ui_presented`.

يملك `TiktigerRuntimeCoordinator` في Host استدعاء `dlopen`، والـretained handle طوال عمر التطبيق، و`dlsym`، وتسجيل `dlerror()`، وتمرير UI milestones بعد فحص view hierarchy. على Simulator يطبق `targetEnvironment(simulator)` ويُتخطى تحميل device dylib، كما تمنع PBX platform filter تضمين device dylib في Simulator.

## Required symbol matrix from actual artifact

| Symbol | Artifact status | Runtime meaning |
|---|---|---|
| `tt_product_name` | **FOUND** | Product identity |
| `tt_version` | **FOUND** | Version 1.1 |
| `tt_runtime_initialize` | **FOUND** | Host initialization |
| `tt_runtime_dylib_loaded` | **FOUND** | C load state |
| `tt_runtime_initializer_executed` | **FOUND** | C initializer state |
| `tt_runtime_core_started` | **FOUND** | Core state |
| `tt_runtime_feature_registry_ready` | **FOUND** | Registry state |
| `tt_runtime_mark_ui_registered` | **FOUND** | Host-owned registration marker |
| `tt_runtime_mark_ui_presented` | **FOUND** | Host-owned presentation marker |
| `tt_runtime_ui_registered` | **FOUND** | UI registration getter |
| `tt_runtime_ui_presented` | **FOUND** | UI presentation getter |
| `tt_runtime_diagnostics_json` | **FOUND** | Runtime diagnostics JSON |
| `tt_feature_count` | **FOUND** | Registry enumeration |
| `tt_feature_key_at` | **FOUND** | Registry key lookup |
| `tt_set_feature_enabled` | **FOUND** | Registry forwarding |
| `tt_set_download_stage` | **FOUND** | Download stage forwarding |

`FOUND` هنا نتيجة `nm -gU` وsymbol status داخل artifact، وليست Runtime execution evidence.

## Runtime milestones

| Order | Milestone | Simulator build/run status | Real-device status | Required evidence |
|---:|---|---|---|---|
| 1 | `dylib_loaded` | **NOT VERIFIED** — device dylib is intentionally skipped on Simulator | **NOT VERIFIED** | device `dlopen` success, path, retained handle, timestamp |
| 2 | `initializer_executed` | **NOT VERIFIED** | **NOT VERIFIED** | real device runtime event and timestamp |
| 3 | `core_started` | **NOT VERIFIED** | **NOT VERIFIED** | real device C runtime event and timestamp |
| 4 | `feature_registry_ready` | **NOT VERIFIED** | **NOT VERIFIED** | registry count/key event and timestamp |
| 5 | `ui_registered` | Simulator launched and screenshot captured, but this is not the Host hierarchy milestone | **NOT VERIFIED** | Host probe event after window/superview confirmation |
| 6 | `ui_presented` | **NOT VERIFIED** by Host hierarchy probe | **NOT VERIFIED** | Host probe event with registered view, window, superview, and non-empty bounds |

## Simulator smoke evidence

The successful CI smoke test recorded:

```text
SIMULATOR DEVICE: F057F93D-2562-418F-AB4C-35C3B965CD8D BOOTED
SIMULATOR SIGNING: SUCCEEDED
APP INSTALL: SUCCEEDED
UI LAUNCH: SUCCEEDED
UI SCREENSHOT: CAPTURED
RUNTIME SMOKE STATUS: SUCCEEDED
DEVICE DYLIB LOADED: NOT VERIFIED — simulator guard intentionally skips device dylib
UI PRESENTED: NOT VERIFIED by Host hierarchy probe
```

This proves the Simulator app could be signed, installed, launched, and screenshotted after the TigerCore framework install name was corrected to `@rpath/TigerCore.framework/TigerCore`. It does not prove device dylib execution.

## Required device evidence

After owner eSign installation, open Diagnostics and export:

```text
device-runtime.json
device-console.log
DEVICE_RUNTIME_VERIFICATION.md
```

The final device report must include real timestamps and log lines for the six milestones, the actual dylib path, `dlopen`, `dlerror`, each `dlsym`, Core version, app version, iOS version, device identifier, and last runtime error. No tokens, cookies, credentials, or private user data may be included.

## Current conclusion

| Item | Result |
|---|---|
| Constructor sets UI milestones | **NO** |
| Host owns UI milestone updates | **YES** |
| Retained `dlopen` handle | **YES** |
| `dlerror()` and `dlsym` reporting | **YES** |
| TigerCore runtime install name | **FIXED to @rpath** |
| Simulator smoke | **SUCCEEDED** |
| Device dylib runtime | **NOT VERIFIED** |
| Real Host launch log from iPhone | **NOT CAPTURED** |
| `TIKTIGER RUNTIME VERIFIED` | **NO** |
| `XCODE VERIFIED` | **YES** |

## References

[1]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerRuntimeCoordinator.swift
[2]: Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/src/TiktigerRuntime.c
[3]: Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/include/Tiktiger.h
[4]: .github/workflows/build-tiktiger-ios.yml
[5]: Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj/project.pbxproj

الأدلة المصدرية هي [1]–[5]، والدليل التنفيذي هو `verification.txt`, `symbol_status.txt`, و`runtime_smoke_test.txt` داخل artifact run `32389935401`.
