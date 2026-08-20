# Tiktiger 1.1 — Feature Verification

هذا التقرير يفرق بين **مسار مصدر مكتمل** وبين **Runtime evidence**. نجاح Xcode Build وSimulator smoke لا يثبت تشغيل device dylib أو `ui_presented` على iPhone حقيقي. لذلك لا توجد هنا حالة `VERIFIED` لأي ميزة لم تُختبر بفعل حقيقي.

## الحالات الأساسية

| Feature | Source path | Status | Evidence and remaining proof |
|---|---|---|---|
| Master Switch | `ContentView.swift` → `TiktigerSettingsStore` → `TigerManager`/Registry → UserDefaults → dependent rows | **IMPLEMENTED NOT TESTED** | الحالة العامة محفوظة، dependent states تُعطل وتُستعاد، وDiagnostics تسجل state/registry/persistence events؛ يحتاج enable/disable/relaunch على جهاز. |
| Appearance | `AppearanceSectionView` → `TiktigerAppearanceService` → `preferredColorScheme` وAppStorage | **IMPLEMENTED NOT TESTED** | Light/Dark/System، persistence، runtime switching وRoot-wide propagation موجودة؛ يحتاج فحص جميع الشاشات وSheets وrestart. |
| Translation | `TranslationSectionView` → `TiktigerLocalizationService` → `en/ar Localizable.strings` → layoutDirection | **IMPLEMENTED NOT TESTED** | English/Arabic، LTR/RTL، persistence وruntime refresh موجودة؛ Spanish/Vietnamese تستخدم fallback English؛ يحتاج فحص النصوص على الجهاز وrestart. |
| Diagnostics | `DiagnosticsView` → `TiktigerDeviceDiagnostics` → Application Support → Share Sheet | **IMPLEMENTED NOT TESTED** | timestamps، dlsym/dlopen، milestones، feature audit، sanitization، وملفات التصدير الثلاثة موجودة؛ يحتاج Export فعلي من iPhone. |
| Direct HTTPS Download | `DownloadCenterView` → `TiktigerMediaDownloadService` → `TiktigerDirectHTTPSProvider` → URLSession | **IMPLEMENTED NOT TESTED** | HTTPS/host/HTTP/MIME/filename/progress/history/error/cancel/retry paths موجودة؛ يحتاج رابط HTTPS مصرح وتجربة Runtime. |
| Published/Page URL Download | Download Center input → provider boundary | **PROVIDER REQUIRED** | لا يوجد fake resolver؛ يلزم Provider/API مصرح يحول page URL إلى direct media URL. |
| Cancel | Download Center → service cancel → URLSession/AVAssetExportSession | **IMPLEMENTED NOT TESTED** | cancellation حقيقي وtyped audit events موجودان؛ يحتاج إلغاء network وaudio export على الجهاز. |
| Retry | Retry button → `retryLast()` → same provider/service path | **IMPLEMENTED NOT TESTED** | retryable URL وfailure→retry path موجودان؛ يحتاج اختبار failure ثم retry. |
| Photos Save | media service → PHPhotoLibrary addOnly → PHAssetCreationRequest | **DEVICE TEST REQUIRED** | المسار والصلاحيات والأخطاء موجودة؛ يحتاج authorized/denied/restricted/success/failure على iPhone. |
| M4A Extraction | Download Center Audio mode → AVAsset → AVAssetExportSession AppleM4A | **DEVICE TEST REQUIRED** | audio-track/export/cancel/output/share paths موجودة؛ يحتاج valid/invalid/no-audio/export/cancel/playability test. |
| Share | `TiktigerShareService` → file validation → `UIActivityViewController` | **IMPLEMENTED NOT TESTED** | missing-file، completion، cancel، error، multi-file Diagnostics export، وcleanup بعد completion موجودة؛ يحتاج Share Sheet فعلي. |
| Face ID | protected toggle → `TiktigerLocalAuth` → LAContext | **DEVICE TEST REQUIRED** | availability/success/failure/cancel paths مسجلة ومترجمة؛ يحتاج Face ID/passcode/unavailable/not-enrolled test. |
| Chats Lock | toggle → LocalAuthentication → registry/local state | **PARTIAL** | auth وstate persistence موجودان، لكن Host لا يحتوي Chats protected screen أو unlock flow حقيقي؛ لا fake Chats. |
| Favorites Lock | toggle → LocalAuthentication → registry/local state | **PARTIAL** | auth وstate persistence موجودان، لكن Host لا يحتوي Favorites protected state أو unlock flow حقيقي؛ لا fake Favorites. |

## C Registry boundaries

| Registry key | Status | Limitation |
|---|---|---|
| `downloadMedia` | **IMPLEMENTED NOT TESTED** | Host direct HTTPS service موجود، لكنه لا يحول page URL. |
| `downloadStories` | **PROVIDER REQUIRED** | لا يوجد story resolver/provider. |
| `downloadAudio` | **DEVICE TEST REQUIRED** | M4A path موجود ويحتاج iOS media test. |
| `readChats` | **NOT IMPLEMENTED** | registry key بلا Chats Host hook. |
| `ghostTyping` | **NOT IMPLEMENTED** | لا يوجد message composer hook. |
| `lockChats` | **PARTIAL** | LocalAuth/toggle فقط؛ protected state غير موجودة. |
| `lockFavorites` | **PARTIAL** | LocalAuth/toggle فقط؛ protected state غير موجودة. |
| `privateProfile` | **PARTIAL** | state/toggle بلا profile controller/provider. |
| `liquidControls` | **PARTIAL** | preference/registry flag بلا Host-wide external effect. |
| `followConfirm` | **PARTIAL** | state/toggle بلا follow action controller. |

## Build boundary

GitHub Actions run `32389935401` من commit `18d30a03f5b3cbe220c6cc8896c30beca8c78ab6` سجل `BUILD SUCCEEDED` لـdylib وHost device وHost simulator، ونجح unsigned IPA packaging وSimulator signing/install/launch/screenshot. هذا دليل Build/Simulator فقط؛ `dylib_loaded` وCore/Registry/UI milestones الخاصة بالـdevice تبقى غير مثبتة.

## مراجع داخلية

[1]: Tiktiger_1.1/TiktigerHost/TigerHost/ContentView.swift
[2]: Tiktiger_1.1/TiktigerHost/TigerHost/Services/TiktigerMediaDownloadService.swift
[3]: Tiktiger_1.1/TiktigerHost/TigerHost/Services/TiktigerSettingsStore.swift
[4]: Tiktiger_1.1/TiktigerHost/TigerHost/Services/TiktigerAppearanceService.swift
[5]: Tiktiger_1.1/TiktigerHost/TigerHost/Services/TiktigerLocalizationService.swift
[6]: Tiktiger_1.1/TiktigerHost/TigerHost/Services/TiktigerShareService.swift
[7]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerDeviceDiagnostics.swift
[8]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerRuntimeCoordinator.swift
[9]: Tiktiger_1.1/TiktigerHost/TigerCore/TigerManager.m
[10]: Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj/project.pbxproj
[11]: Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/src/TiktigerFeatures.c
[12]: Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/src/TiktigerRuntime.c

الأدلة المصدرية هي [1]–[12]، وأدلة Build محفوظة في artifact run `32389935401`.
