# Tiktiger 1.1 — Feature End-to-End Map

## نطاق التدقيق

تطبق هذه الوثيقة القاعدة التالية على Host الحالي:

> **UI → User Action → Controller/ViewModel → Service → Provider/System API → Validation → Result/Error → Persistence/State → UI Feedback → Diagnostics**

هذه خريطة مصدرية وتشغيلية، وليست بديلًا عن اختبار iPhone حقيقي. لا تُرفع أي ميزة إلى `VERIFIED` بسبب وجود زر أو symbol أو نجاح Build فقط. الحالة `VERIFIED` لا تُستخدم إلا بعد نجاح فعل حقيقي وتسجيله في Feature Runtime Audit أو تقرير الجهاز.

| الحالة | المعنى |
|---|---|
| `VERIFIED` | نجاح Runtime فعلي موثق، وليس دليل مصدر أو Build. |
| `IMPLEMENTED NOT TESTED` | مسار Host موجود ويمكن تتبعه، لكن اختبار الجهاز/السيناريو لم يكتمل. |
| `DEVICE TEST REQUIRED` | يعتمد على صلاحية iOS أو Hardware/System UI ولا يثبت من CI فقط. |
| `PARTIAL` | جزء من المسار موجود، لكن Integration أو protected state أو completion ما زال ناقصًا. |
| `PROVIDER REQUIRED` | يحتاج Provider/API مصرحًا لاستخراج المصدر أو تحويل Page URL إلى Media URL. |
| `FAILED` | يوجد دليل Runtime فعلي على الفشل. |
| `NOT IMPLEMENTED` | لا يوجد مسار تنفيذ حقيقي من الإدخال إلى النتيجة. |

## الهوية والحدود الثابتة

| العنصر | القيمة |
|---|---|
| Host Bundle ID | `com.ucorc.Tiktiger` |
| Core Bundle ID | `com.ucorc.TiktigerCore` |
| الإصدار | `1.1` |
| dylib المعتمدة | `Tiktiger.dylib` |
| dylib SHA-256 | `c74d63937efdb58421382910e0de0c5cd23dd8ee046c986f8f4698e678a31c80` |
| dylib install name | `@rpath/Tiktiger.dylib` |
| TigerCore framework install name | `@rpath/TigerCore.framework/TigerCore` |
| Host runpath | `@executable_path/Frameworks` |
| تغييرات dylib | لا توجد؛ لم يُعاد بناء أو استبدال binary خارج Xcode verification المعتمد |

## خريطة الميزات الأساسية

| Feature | UI / Action | Service وSystem API | Validation وFailure | Persistence وUI Update | Diagnostics | Status |
|---|---|---|---|---|---|---|
| Master Switch | `ContentView.statusCard` يستخدم `Toggle` عبر `TiktigerSettingsStore` | `TigerManager.isEnabled`، `UserDefaults`، و`TiktigerRuntimeCoordinator.setFeature` لكل Registry key على الجهاز | يعيد failure إذا رفض Registry أي dependent feature؛ لا يسمح صفوف الميزات بتغيير الحالة عند إيقاف Master | القيمة العامة محفوظة في `tiktiger.master.enabled`؛ عند الإيقاف تُرسل dependent states كـfalse، وعند التفعيل تُستعاد القيم المحفوظة؛ البطاقة والصفوف تتحدث | `action_started`, `service_called`, `persistence_updated`, `registry_updated`, `state_changed`, `success/failure` | **IMPLEMENTED NOT TESTED** |
| Appearance | `AppearanceSectionView`: Glass toggles، gradient، accent، وTheme Picker | `TiktigerAppearanceService` يطبق `preferredColorScheme` من Root على كل Host وSheets | `Mode` مقيد إلى `system/light/dark`؛ reset يعيد state معروفًا | `tiktiger.appearance.mode` و`@AppStorage` للقيم الأخرى؛ Root يعيد الرسم، وPicker/controls تُحدّث مباشرة | Appearance يسجل action/service/persistence/state/result/success | **IMPLEMENTED NOT TESTED** |
| Translation | `TranslationSectionView` يختار اللغة من Picker | `TiktigerLocalizationService` يقرأ `Localizable.strings` من Bundle ويطبق `layoutDirection` على Root | اللغات الحالية `en/ar/es/vi`؛ موارد English/Arabic فعلية، وfallback English يمنع ظهور localization keys للغات التي لا تملك resource مستقلًا | `tiktiger.language` محفوظ؛ تبديل اللغة يعيد النصوص المرتبطة بالخدمة ويطبق RTL للعربية | Translation يسجل action/service/persistence/state/result/success | **IMPLEMENTED NOT TESTED** |
| Diagnostics | `DiagnosticsView` وزر `Export Runtime Report` | `TiktigerDeviceDiagnostics.exportRuntimeReport()`، Application Support، Foundation Share Sheet | JSON/Markdown مبني من runtime/symbol/feature records، وsanitization لا يسجل Tokens/Cookies/Credentials | ينشئ `device-runtime.json`, `device-console.log`, `DEVICE_RUNTIME_VERIFICATION.md` ويمرر الملفات الثلاثة إلى Share Sheet | timestamps، dlopen/dlerror، dlsym، milestones، feature audit، export error | **IMPLEMENTED NOT TESTED** |
| Direct HTTPS Download | `DownloadCenterView` URL input ثم `Start Download` | `TiktigerMediaDownloadService` و`TiktigerDirectHTTPSProvider` باستخدام `URLSession.download` | HTTPS فقط، URL/host، HTTP 2xx، MIME/extension، temp file، safe filename، وtyped errors | progress stage، lastError، Photos status، history في UserDefaults، last retry في الذاكرة | `action_started`, `service_called`, `state_changed`, `result_success/failure`, persistence، error | **IMPLEMENTED NOT TESTED** |
| Published/Page URL Download | نفس input، لكن Page URL ليس Media URL | لا يوجد resolver/provider في المصدر الحالي | لا يوجد تحويل آمن ومصرح من Page URL إلى media URL | لا توجد نتيجة نجاح مزعومة | يظهر Provider boundary في Diagnostics/map | **PROVIDER REQUIRED** |
| Cancel | زر `Cancel` أثناء `isBusy` | `downloadTask.cancel()`, `AVAssetExportSession.cancelExport()`, `Task.checkCancellation()` | CancellationError يتحول إلى Cancel state؛ failure لا يترك busy عالقًا | `Cancelled` stage وorange state، مع بقاء history السابقة | `action_started`, `cancel`, `result_success` بتفصيل cancellation | **IMPLEMENTED NOT TESTED** |
| Retry | `Retry Last Download` عندما `canRetry` | يعيد `download(urlString:mode:)` عبر نفس provider/service | يفشل مغلقًا عند عدم وجود retryable URL؛ المحاولة الجديدة تعيد validation/error path | history محفوظة؛ retry URL موجود في الذاكرة حتى نهاية session | action/service/result/error/state events | **IMPLEMENTED NOT TESTED** |
| Photos Save | Download media ثم `saveToPhotos` | `PHPhotoLibrary.requestAuthorization(.addOnly)` و`PHAssetCreationRequest` | authorized/limited فقط؛ denied/restricted/save failure تسجل typed failure | `Requesting` → `Saving` → `Saved` أو Permission denied؛ history بعد النجاح | Photos service/result_success/success أو result_failed/failure | **DEVICE TEST REQUIRED** |
| M4A Extraction | Download Center mode `Audio M4A` ثم Share | `AVAsset` و`AVAssetExportSession` preset `AppleM4A` | audio track، exporter، MIME/media type، output existence، cancellation | `.m4a` إلى Documents، `lastFileURL`، Audio ready، history بعد success | M4A stage/result/success/error/cancel events | **DEVICE TEST REQUIRED** |
| Share | Share M4A أو Export Runtime Report | `TiktigerShareService` ثم `UIActivityViewController` | يتحقق من file existence/readability قبل العرض؛ completion/error/cancel يسجل؛ temp cleanup بعد completion فقط | يدعم ملفًا واحدًا أو الملفات الثلاثة للتقرير؛ لا يحذف Documents output | `action_started`, `service_called`, `state_changed`, `result_success/failure`, `success`, `cancel` | **IMPLEMENTED NOT TESTED** |
| Face ID | Protected toggle يستدعي `TiktigerLocalAuth` | `LAContext.canEvaluatePolicy` و`evaluatePolicy(.deviceOwnerAuthentication)` | unavailable/rejected/failure لا يغير toggle؛ user/system cancel يسجل `cancel` | state يتغير بعد success فقط، وFace ID dialog localized | Face ID/Auth action/service/result/success/failure/cancel | **DEVICE TEST REQUIRED** |
| Chats Lock | `TiktigerFeatureRow` لـ`lockChats` | LocalAuthentication ثم RuntimeCoordinator/Manager state إذا كان Registry key موجودًا | auth success وRegistry success مطلوبان؛ لا يوجد protected Chats screen في Host | toggle وfeature key محفوظان بعد success فقط | Auth وregistry/persistence/state events | **PARTIAL** |
| Favorites Lock | `TiktigerFeatureRow` لـ`lockFavorites` | LocalAuthentication ثم RuntimeCoordinator/Manager state إذا كان Registry key موجودًا | auth success وRegistry success مطلوبان؛ لا توجد Favorites unlock gate في Host | toggle وfeature key محفوظان بعد success فقط | Auth وregistry/persistence/state events | **PARTIAL** |

## Additional visible rows without full Host integration

| المجموعة | IDs | النقص | Status |
|---|---|---|---|
| Profile | `profileStats`, `followerFormat` | لا يوجد Profile service أو Host hook | **NOT IMPLEMENTED** |
| Profile | `privateProfile`, `followConfirm` | Registry/local state فقط؛ لا يوجد profile/follow controller | **PARTIAL** |
| Stories | `storyViews`, `anonymousStories` | لا يوجد Stories provider أو host integration | **PROVIDER REQUIRED** |
| Stories | `storyGradient` | preference/visual setting فقط | **PARTIAL** |
| Chats | `videoVoice` | M4A موجود، لكن لا يوجد message composer/controller | **PARTIAL** |
| Chats | `undoMessages`, `keepDeleted` | لا يوجد message storage/controller | **NOT IMPLEMENTED** |
| Downloads | `downloadAvatar`, `downloadComments`, `downloadStickers` | لا يوجد specific provider/action path | **PROVIDER REQUIRED** |
| Videos | `progressBar`, `likeConfirm`, `showUsername`, `showFlag` | لا يوجد Video host hook/controller | **NOT IMPLEMENTED** |
| Privacy | `hideAds`, `multiAccount` | لا يوجد Host integration أو system service | **NOT IMPLEMENTED** |
| Privacy | `clearHistory` | local setting فقط؛ لا يوجد lifecycle action كامل | **PARTIAL** |
| Appearance | `liquidNotices`, `liquidOverlays`, `oledKeyboard` | preference paths موجودة، لكن ليست Host-wide system effects | **PARTIAL** |
| Miscellaneous | `copyText`, `openLinks`, `fastLogout` | لا يوجد dedicated action/service/result path | **NOT IMPLEMENTED** |

## Runtime Core وHost ownership

1. على `iphoneos` يبدأ `TiktigerRuntimeCoordinator.start()`، ويستدعي `dlopen` مع retained handle طوال عمر التطبيق، ويسجل كل candidate path و`dlerror()`.
2. يستدعي Host `dlsym` لكل symbol مطلوب ويسجل `FOUND/FAILED` مع timestamp.
3. يستدعي `tt_runtime_initialize()` بعد نجاح التحميل. Constructor C يثبت فقط `dylib_loaded`, `initializer_executed`, `core_started`, و`feature_registry_ready`.
4. Host view-hierarchy probe وحده يسجل `ui_registered` و`ui_presented`. لا يعلن constructor أي UI milestone.
5. `ui_presented` لا يصبح VERIFIED إلا بعد وجود view داخل window وsuperview وبounds غير فارغة وبعد `ui_registered`.

| Milestone | Owner | Build/Simulator status | Real-device status |
|---|---|---|---|
| `dylib_loaded` | Host `dlopen` + C runtime | NOT VERIFIED؛ Simulator guard يتخطى device dylib | **PENDING device-runtime.json** |
| `initializer_executed` | Host initialize/C runtime | NOT VERIFIED على Simulator | **PENDING device-runtime.json** |
| `core_started` | C runtime | NOT VERIFIED على Simulator | **PENDING device-runtime.json** |
| `feature_registry_ready` | C registry count/key | NOT VERIFIED على Simulator | **PENDING device-runtime.json** |
| `ui_registered` | Host hierarchy probe | UI launch/screenshot فقط، لا milestone claim | **PENDING Host probe evidence** |
| `ui_presented` | Host hierarchy probe | NOT VERIFIED | **PENDING Host probe evidence** |

## Build evidence boundary

GitHub Actions run `32389935401` من commit `18d30a03f5b3cbe220c6cc8896c30beca8c78ab6` نجح في dylib build، Host device build، Host simulator build، unsigned IPA packaging، simulator signing/install/launch/screenshot، ورفع artifacts. هذا لا يثبت Runtime device ولا يرفع أي milestone إلى VERIFIED.

## References

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

المراجع الداخلية في [1]–[12] هي ملفات المصدر التي يمكن تدقيقها داخل المستودع؛ Build evidence محفوظ في artifact الخاص بـrun `32389935401`.
