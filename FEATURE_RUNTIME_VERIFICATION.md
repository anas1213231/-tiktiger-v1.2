# Tiktiger 1.1 — Feature Runtime Verification

هذا التقرير يميز بين **مسار مصدر مكتمل** و**اختبار Runtime فعلي**. لا توجد حالة `VERIFIED` هنا لمجرد نجاح Xcode أو Simulator؛ الميزات التي تعتمد على iOS permission أو Share Sheet أو media output تحتاج اختبار iPhone حقيقي.

| Feature | UI | Action | Controller / Service | API / Provider | Validation | Success path | Failure / Cancel | UI result | Diagnostics | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| Master Switch | Status card + global Toggle | Enable/disable | `TiktigerSettingsStore` → `TigerManager` + RuntimeCoordinator | UserDefaults + C registry | bool state and registry update results | persist global state → update registry → dependent rows refresh | registry error/failure recorded; no silent success | card and dependent rows reflect global state | action, registry_updated, persistence_updated, state_changed, success/failure | **IMPLEMENTED NOT TESTED** |
| Appearance | Appearance section and mode Picker | Select Light/Dark/System or reset | `TiktigerAppearanceService` | SwiftUI `preferredColorScheme`, AppStorage | mode enum and color state | persist mode → Root environment updates → all Host screens/sheets refresh | invalid mode is prevented by enum; reset returns known state | theme changes through Root | action, service, persistence, state, success | **IMPLEMENTED NOT TESTED** |
| Translation | Translation Picker | Select English/Arabic | `TiktigerLocalizationService` | `Localizable.strings`, `layoutDirection` | supported language and fallback bundle | persist language → localized resources → RTL/LTR → Root refresh | missing resource falls back to English; keys are not surfaced | translated strings and direction update | action, service, persistence, state, success | **IMPLEMENTED NOT TESTED** |
| Diagnostics | Runtime Verification card + Export button | Export Runtime Report | `TiktigerDeviceDiagnostics` → `TiktigerShareService` | Application Support + UIKit Share Sheet | snapshot sanitization and file existence | write JSON/log/Markdown → validate files → present Share Sheet | export error or Share cancel recorded; files are not deleted before completion | report files offered to user | runtime, symbols, feature audit, export result | **IMPLEMENTED NOT TESTED** |
| Direct HTTPS Download | Download Center URL field + Start | Start download | `TiktigerMediaDownloadService` | `TiktigerDirectHTTPSProvider` + URLSession | HTTPS, host, HTTP 2xx, MIME, extension, safe filename | download → validate → stage/progress → save/history → UI | typed URL/HTTP/MIME/Photos errors; cancellation is real Task cancellation | progress, lastError, history, retry state | action, service, state, success/failure, cancel, error | **IMPLEMENTED NOT TESTED** |
| Published/Page URL Download | Same URL field | Submit page URL | No resolver implementation | No authorized provider present | no safe page-to-media transformation | none claimed | Provider boundary reported | provider-required state only | provider status | **PROVIDER REQUIRED** |
| Cancel | Cancel button during busy state | Cancel active operation | Media service | URLSession task / AVAssetExportSession | active task/export session check | cancel task → Cancelled stage → busy false | cancellation event is not treated as successful media output | Cancelled stage and action remains usable | cancel and result event | **IMPLEMENTED NOT TESTED** |
| Retry | Retry Last Download button | Retry last request | `retryLast()` → media service | same direct provider | retry URL exists | repeat validation/download path | no retry URL or retry error is recorded | retry button/state updates | action, service, success/failure/error | **IMPLEMENTED NOT TESTED** |
| Photos Save | Download completion / save state | Save media to Photos | Media service `saveToPhotos` | Photos Add Only + PHAssetCreationRequest | authorization and file/media type | request permission → create asset → history/UI success | denied/restricted/save error | Saved or permission/error state | Photos service/result success/failure | **DEVICE TEST REQUIRED** |
| M4A Extraction | Audio M4A mode + Share | Extract audio | Media service `extractAudio` | AVAsset + AVAssetExportSession AppleM4A | audio track, exporter, output file | download → export → Documents `.m4a` → Share | no audio/export failure/cancel | Audio ready / last file / error | M4A action/stage/success/failure/cancel | **DEVICE TEST REQUIRED** |
| Share | Share file / Export report | Present system share UI | `TiktigerShareService` → wrapper | `UIActivityViewController` | file exists/readable | validate → present → completion → cleanup temporary files | missing file, error, user cancel | Share Sheet plus result audit | start, service, success/failure/cancel | **IMPLEMENTED NOT TESTED** |
| Face ID | Protected feature toggle | Authenticate before enabling | `TiktigerLocalAuth` | LocalAuthentication `LAContext` | canEvaluatePolicy and auth result | success → persist state/registry update | unavailable/rejected/cancel keeps state unchanged | toggle changes only after success | auth action/service/success/failure/cancel | **DEVICE TEST REQUIRED** |
| Chats Lock | `lockChats` Toggle | Authenticate and enable setting | LocalAuth + registry/store | LocalAuthentication + C registry | auth and registry result | setting persists after auth | failure/cancel does not enable | toggle only; no Chats protected screen exists | auth/registry/persistence events | **PARTIAL** |
| Favorites Lock | `lockFavorites` Toggle | Authenticate and enable setting | LocalAuth + registry/store | LocalAuthentication + C registry | auth and registry result | setting persists after auth | failure/cancel does not enable | toggle only; no Favorites protected screen exists | auth/registry/persistence events | **PARTIAL** |

## Runtime Core evidence boundary

| Milestone | Simulator smoke | Real-device report |
|---|---|---|
| `dylib_loaded` | **NOT VERIFIED** because simulator guard skips device dylib | **NOT VERIFIED / pending** |
| `initializer_executed` | **NOT VERIFIED** | **NOT VERIFIED / pending** |
| `core_started` | **NOT VERIFIED** | **NOT VERIFIED / pending** |
| `feature_registry_ready` | **NOT VERIFIED** | **NOT VERIFIED / pending** |
| `ui_registered` | launch/screenshot succeeded, but Host hierarchy marker not claimed | **NOT VERIFIED / pending** |
| `ui_presented` | **NOT VERIFIED** by view-hierarchy probe | **NOT VERIFIED / pending** |

## Required device test matrix

The owner must run the following after eSign installation and export the three Self-Diagnostics files: Master Switch enable/disable/relaunch; Light/Dark/System and restart; English/Arabic RTL/LTR and restart; valid/invalid HTTPS download; HTTP/MIME failure; cancel; retry; Photos authorization and save; M4A valid/no-audio/export/cancel; Share valid/missing/cancel/completion; Face ID success/failure/cancel/unavailable; and Chats/Favorites lock persistence plus the limitation that no protected Host screen currently exists.

## Security boundary

Runtime reports must not contain Authorization headers, cookies, credentials, private keys, personal data, or sensitive URL query values. The diagnostics sanitizer is expected to redact those classes before export.

## References

[1]: FEATURE_END_TO_END_MAP.md
[2]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerDeviceDiagnostics.swift
[3]: Tiktiger_1.1/TiktigerHost/TigerHost/Services/TiktigerMediaDownloadService.swift
[4]: Tiktiger_1.1/TiktigerHost/TigerHost/Services/TiktigerShareService.swift
[5]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerRuntimeCoordinator.swift
[6]: RUNTIME_VERIFICATION.md

المراجع الداخلية هي [1]–[6]، بينما أي `VERIFIED` نهائي يجب أن يعتمد على التقارير المصدرة من iPhone الحقيقي.
