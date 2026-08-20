# Tiktiger 1.1 — Feature End-to-End Map

## نطاق التدقيق

تطبق هذه الوثيقة قاعدة المسار التالية على النسخة الحالية من Tiktiger:

> **UI → User Action → Controller/ViewModel → Service → Provider/System API → Validation → Result/Error → State Update → UI Feedback → Diagnostics**

هذه الوثيقة هي **تدقيق للمصدر والمسارات الموجودة**، وليست بديلًا عن اختبار جهاز حقيقي. لم يتم تعديل Features أو UI أو Architecture أو `Tiktiger.dylib` أثناء إعدادها، ولم يتم تحويل أي حالة إلى `VERIFIED` لمجرد وجود زر أو function أو نجاح Build.

الحالات المستخدمة هنا هي الحالات المسموح بها في متطلبات المشروع:

| الحالة | معناها في هذا التقرير |
|---|---|
| `VERIFIED` | يوجد دليل Runtime فعلي من الاختبار المطلوب، وليس مجرد دليل مصدر أو Build. |
| `IMPLEMENTED NOT TESTED` | المسار البرمجي موجود ويمكن تتبعه، لكن الاختبار التشغيلي المطلوب لم يكتمل. |
| `DEVICE TEST REQUIRED` | المسار يعتمد سلوك iOS أو صلاحية جهاز أو Hardware/System UI لا يثبت من Linux أو Build فقط. |
| `PARTIAL` | جزء من المسار موجود، لكن Service أو Provider أو Integration أو State/UI completion مفقود. |
| `PROVIDER REQUIRED` | يلزم Provider/API مصرح لاستخراج أو تنفيذ المصدر المطلوب. |
| `FAILED` | يوجد دليل فعلي على فشل المسار. |
| `NOT IMPLEMENTED` | لا يوجد مسار تنفيذ حقيقي من الإدخال إلى النتيجة. |

## الهوية والحدود الثابتة

| العنصر | القيمة |
|---|---|
| التطبيق المضيف | `com.ucorc.Tiktiger` |
| Core framework | `com.ucorc.TiktigerCore` |
| الإصدار | `1.1` |
| dylib المعتمدة | `Tiktiger.dylib` |
| SHA-256 قبل توقيع eSign | `c74d63937efdb58421382910e0de0c5cd23dd8ee046c986f8f4698e678a31c80` |
| Runtime device path | `Frameworks/Tiktiger.dylib` داخل التطبيق |
| Install name | `@rpath/Tiktiger.dylib` |
| Host runpath | `@executable_path/Frameworks` |

## خريطة Features الأساسية المطلوبة

| Feature | UI File | Action | ViewModel / Controller | Service | Provider / System API | Input Validation | Success Path | Failure Path | Cancel Path | Persistence | UI Result | Diagnostics Event | Runtime Test | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Master Switch | `ContentView.swift`، بطاقة الحالة والتبديل | `Toggle` في `statusCard` يكتب `TigerManager.shared.isEnabled` | لا يوجد ViewModel مستقل؛ `ContentView` ينفذ التغيير مباشرة | `TigerManager` property فقط | لا يوجد forwarding إلى Core registry عند تغيير Master Switch | لا يوجد validation مستقل أو منع لحالة غير صالحة | تتغير حالة البطاقة داخل SwiftUI إلى Ready/disabled | لا توجد نتيجة فشل من Service؛ setter لا يعيد نتيجة | غير مطلوب لمسار التبديل القصير | **غير محفوظ**؛ `TigerManager.shared` يبدأ `enabled = YES` في الذاكرة عند إنشاء singleton | تحديث مباشر لحالة البطاقة | يسجل `action_started` و`service_called` و`result_success` في `ContentView.swift` | Enable/Disable/Restart/تأثير الميزات التابعة لم يثبت على جهاز | **PARTIAL** |
| Appearance | `AppearanceSectionView` | Toggles، Picker، ColorPicker، Reset | لا يوجد Appearance ViewModel؛ `@AppStorage` يربط Action بالتخزين | لا يوجد Appearance Service مستقل | SwiftUI/AppStorage فقط؛ لا يوجد تطبيق شامل على Host أو Core | `Color` يستخرج RGB، لكن لا توجد validation لسياسة theme كاملة | تحفظ قيم glass/gradient/color وتعيد رسم controls التي تقرأها | لا توجد typed service errors؛ Reset لا يسجل نتيجة | غير موجود لمسار تغيير سريع | `@AppStorage` يحفظ preferences | يعرض controls وقيمًا محلية؛ لا يثبت Full UI Refresh لكل الشاشات | `Appearance` يسجل action/service/result، لكن بعض toggles تتبع preferences فقط | Light/Dark/System/Runtime refresh/Restart/كل الشاشات لم يثبت | **PARTIAL** |
| Translation | `TranslationSectionView` | Picker يغير `@AppStorage("tiktiger.language")` | لا يوجد Localization ViewModel | لا يوجد Localization Service | `AppStorage` فقط؛ لا توجد localization resource pipeline كاملة | القيم مقيدة إلى `en/ar/es/vi` | تحفظ اللغة محليًا | لا يوجد مسار فشل أو missing-key validation | غير موجود | `@AppStorage` يحفظ preference | النص يصرح أن full host localization يطبق بعد launch التالي؛ لا يوجد تبديل RTL/LTR كامل | `Translation` يسجل AppStorage events | Arabic/English/RTL/LTR/Restart/missing-key/runtime switching لم يثبت | **PARTIAL** |
| Diagnostics | `DiagnosticsView` | زر `Export Runtime Report` | `TiktigerDeviceDiagnostics` singleton | `exportRuntimeReport()` | Foundation file storage وiOS share sheet عبر `TiktigerShareSheet` | Snapshot JSON/Markdown مبني من records؛ sanitization يزيل auth/cookie material | ينشئ `device-runtime.json` و`device-console.log` و`DEVICE_RUNTIME_VERIFICATION.md` ثم يفتح Share Sheet | `do/catch` يعرض `exportError` ويترك الحدث غير ناجح دون ادعاء VERIFIED | Share cancellation ليس له completion audit خاص | Application Support وJSON logs وconsole log | يعرض milestones وsymbols وpaths وerrors وfeature audit | runtime events، symbol events، feature audit، `report_export` | Export على iPhone الحقيقي لم يثبت بعد | **IMPLEMENTED NOT TESTED** |
| Download | `DownloadCenterView` | URL input ثم `Start Download` | `TiktigerMediaDownloadService` | `performDownload()` و`TiktigerDirectHTTPSProvider` | `URLSession.shared.download(for:)` وdirect HTTPS provider | URL، HTTPS، host، HTTP 2xx، MIME/extension، safe temporary file، filename extension | download → MIME check → temporary file → Photos save → history → UI stage | typed errors لـinvalid URL/HTTPS/HTTP/MIME/Photos/audio، state وlastError وDiagnostics | `Task.cancel()` و`Task.checkCancellation()`، وcancelExport للمسار الصوتي | history محفوظ في UserDefaults؛ last retry URL ليس persistent | progress stage/lastError/photoStatus/history | Download أو M4A يسجل action/service/result/error | direct URL، HTTP error، MIME، failure، cleanup، progress، history لم يختبر على جهاز | **IMPLEMENTED NOT TESTED** للمسار المباشر؛ **PROVIDER REQUIRED** لرابط منشور/page URL |
| Cancel | زر `Cancel` يظهر أثناء `isBusy` | `service.cancel()` | `TiktigerMediaDownloadService` | `downloadTask?.cancel()` و`activeExportSession?.cancelExport()` | Swift Concurrency وAVFoundation | `Task.checkCancellation()` بعد request وقبل processing | ينتقل stage إلى Cancelled ويوقف busy state | cancellation يعالج كـCancellationError ويكتب audit | Cancel حقيقي وليس إخفاء Progress فقط | لا يوجد حفظ مستقل لإلغاء العملية | stage=`Cancelled` وstateColor orange | Download/M4A `result_success` بتفصيل cancelled | اختبار إلغاء network وaudio conversion لم يثبت على الجهاز | **IMPLEMENTED NOT TESTED** |
| Retry | `Retry Last Download` عند `canRetry` | `service.retryLast()` | `TiktigerMediaDownloadService` | يعيد `download(urlString:mode:)` | نفس Provider/URLSession للمحاولة الأصلية | يحتاج `lastRetryURL` و`history.first` | يعيد المسار الكامل من validation إلى success/failure | يسجل failure إذا لا يوجد retryable download؛ أخطاء المحاولة تنتقل للمسار العام | يمكن إلغاء المحاولة عبر Cancel | history محفوظ؛ `lastRetryURL` في الذاكرة فقط | يظهر Retry button وفق `canRetry` ويحدث stage | action/service/result/error | failure ثم retry لم يثبت على جهاز | **IMPLEMENTED NOT TESTED** |
| Photos Save | Download Center و`saveToPhotos` | Download media ثم save operation | `TiktigerMediaDownloadService` | `saveToPhotos()` | `PHPhotoLibrary.requestAuthorization(.addOnly)` و`PHAssetCreationRequest` | authorization must be authorized/limited؛ file URL وmedia type | Photos save success ثم Download completed/history/UI | denied/restricted/save error typed ومعلن في `photoStatus` وDiagnostics | cancellation قبل save وبعد request عبر Task cancellation | history بعد success؛ Photos نفسها يديرها النظام | `Requesting` → `Saving` → `Saved` أو Permission denied | `Photos service_called` وresult_success/result_failed | Authorized/Denied/Restricted/Success/Failure لم يثبت على iPhone | **DEVICE TEST REQUIRED** |
| M4A Extraction | Download Center mode `Audio M4A` وShare M4A | Start Download مع `mode=audio` | `TiktigerMediaDownloadService` | `extractAudio()` | `AVAsset` و`AVAssetExportSession` preset `AppleM4A` | MIME/audio/video type، audio track exists، exporter exists، output URL | download → AVAsset → audio track → real export → `.m4a` output → lastFileURL → Share | no audio/exporter/export status errors تصل إلى `lastError` وDiagnostics | `Task.checkCancellation()` و`activeExportSession.cancelExport()` | output في Documents؛ history بعد success | Audio ready وReady to share، ثم Share button | M4A service/result/error events | valid/invalid media، playable output، conversion/cancel لم يثبت على جهاز | **DEVICE TEST REQUIRED** |
| Share | `DownloadCenterView` و`TiktigerShareSheet` | Button عند وجود `lastFileURL` | لا يوجد Share ViewModel مستقل | `UIActivityViewController` wrapper | UIKit Share Sheet | شرط وجود `lastFileURL` فقط؛ لا يوجد file existence/cleanup completion validation | valid file → Share Sheet presentation | missing file أو UIActivity error غير modeled؛ لا يوجد completion result | user cancel لا يسجل completion محدد | لا يوجد temp cleanup بعد completion في Share layer | Share sheet يظهر؛ لا يوجد نجاح/إلغاء state داخل UI | يسجل `action_started` و`service_called` فقط قبل العرض | valid/missing/cancel/cleanup لم يثبت | **PARTIAL** |
| Face ID | حماية Toggles `lockChats` و`lockFavorites` | Enable protected feature triggers `TiktigerLocalAuth.authenticate` | لا يوجد Auth ViewModel؛ static helper | `TiktigerLocalAuth` | `LAContext.canEvaluatePolicy` و`evaluatePolicy(.deviceOwnerAuthentication)` | policy availability وNSError | success يكمل إلى registry/local state write | unavailable/rejected يسجل result_failed ولا يغير state | system/user cancellation يأتي من LocalAuthentication error، لكن لم يُختبر | toggle state عبر UserDefaults بعد success؛ biometric policy system state خارجي | success يتيح toggle؛ failure يبقيه كما هو | feature action/service/result_success/result_failed | Success/failure/user/system cancel/unavailable/not enrolled لم يثبت | **DEVICE TEST REQUIRED** |
| Chats Lock | `TiktigerFeatureRow` للـ`lockChats` | Toggle enable يطلب LocalAuth | لا يوجد Chats controller أو protected screen | `TiktigerLocalAuth` ثم `TiktigerRuntimeCoordinator.setFeature` إن كان registry key موجودًا | LocalAuthentication + C registry flag | auth success؛ registry set result إذا كان key موجودًا | يحفظ toggle وregistry flag بعد auth | auth failure لا يغير state؛ لا يوجد actual chats lock/unlock screen | لا يوجد unlock flow داخل Chats Host | local feature key محفوظ عبر TigerManager بعد success | يغير toggle فقط؛ لا توجد Chats screen state | Auth events؛ registry events عند path | لا توجد Chats حقيقية مرتبطة بالـHost الحالي | **PARTIAL** |
| Favorites Lock | `TiktigerFeatureRow` للـ`lockFavorites` | Toggle enable يطلب LocalAuth | لا يوجد Favorites controller أو protected screen | `TiktigerLocalAuth` ثم registry flag إن وجد | LocalAuthentication + C registry flag | auth success؛ registry set result | يحفظ toggle وregistry flag بعد auth | auth failure لا يغير state؛ لا يوجد actual favorites unlock gate | لا يوجد unlock flow داخل Favorites Host | local feature key محفوظ بعد success | يغير toggle فقط؛ لا توجد Favorites protected state | Auth events؛ registry events عند path | actual Favorites provider/screen runtime غير موجود | **PARTIAL** |
| Published/page URL Resolver | Download Center النص يقبل direct URL فقط | لا يوجد resolver Action | لا يوجد resolver ViewModel | لا يوجد service/provider للـpost/page URL | لا يوجد API/Provider مصرح | لا يوجد input transformation آمن من page إلى media URL | لا يوجد | يعرض providerRequired فقط في typed error/contract، ولا يوجد تنفيذ فعلي | غير متاح | غير متاح | لا توجد نتيجة | Provider state يظهر في Diagnostics modules | يحتاج Provider فعلي مصرح | **PROVIDER REQUIRED** |

## تفاصيل Runtime Core والـHost

المسار الفعلي للـdylib ليس مجرد وجود binary داخل IPA:

1. `TiktigerRuntimeCoordinator.start()` يبدأ من Host. على `iphoneos` يستدعي `openDylib()`، يحتفظ بـ`dlopen` handle طوال عمر التطبيق، ويسجل كل candidate path و`dlerror()`.
2. `resolveRequiredSymbols()` يستدعي `dlsym` لكل symbol مطلوب، ويحفظ `FOUND/FAILED` وtimestamp وdetail.
3. `tt_runtime_initialize()` يُستدعى من Host بعد التحميل. Constructor الخاص بـC يثبت فقط `dylib_loaded` و`initializer_executed` و`core_started` و`feature_registry_ready`.
4. Host probe `TiktigerRuntimeViewHierarchyProbe` هو الوحيد الذي يستدعي `markUIRegistered` و`confirmPresented`. لا يعلن constructor أي UI milestone.
5. `ui_presented` لا يسجل إلا إذا كان probe داخل `window` و`superview` وله bounds غير فارغة، وبعد تحقق `ui_registered`.

| Milestone | Owner | Evidence source | Current build-only status |
|---|---|---|---|
| `dylib_loaded` | dylib constructor بعد Host `dlopen` | `dlopen` success + C runtime event + Host diagnostics | NOT VERIFIED on simulator; device report required |
| `initializer_executed` | C runtime / Host initialize call | `tt_runtime_initialize` + runtime getter | NOT VERIFIED on simulator; device report required |
| `core_started` | C runtime bootstrap | `tt_runtime_core_started` | NOT VERIFIED on simulator; device report required |
| `feature_registry_ready` | C registry count/getter | `tt_feature_count` + `tt_feature_key_at` | NOT VERIFIED on simulator; device report required |
| `ui_registered` | Host view hierarchy probe | `view.window` + `view.superview` | NOT VERIFIED until Host probe event |
| `ui_presented` | Host view hierarchy probe | registered probe + non-empty bounds | NOT VERIFIED until real Host report |

## Required symbol and registry boundaries

The C registry exposes ten keys. A registry key is not, by itself, a complete host integration.

| C registry key | Registry state | End-to-end host path | Status |
|---|---|---|---|
| `downloadMedia` | `tt_set_feature_enabled` and getter exist | Host direct download service exists, but toggle does not itself invoke a media action | **IMPLEMENTED NOT TESTED** |
| `downloadStories` | registry key exists | no story URL provider/resolver | **PROVIDER REQUIRED** |
| `downloadAudio` | registry key exists | M4A service exists; device media test required | **DEVICE TEST REQUIRED** |
| `readChats` | registry key exists | no Chats host hook/controller | **NOT IMPLEMENTED** |
| `ghostTyping` | registry key exists | no message composer hook | **NOT IMPLEMENTED** |
| `lockChats` | registry key exists | LocalAuth + toggle only; no protected Chats state | **PARTIAL** |
| `lockFavorites` | registry key exists | LocalAuth + toggle only; no protected Favorites state | **PARTIAL** |
| `privateProfile` | registry key exists | toggle/registry state only; no profile navigation/provider | **PARTIAL** |
| `liquidControls` | registry key exists | Appearance preference/registry flag; no full Host effect | **PARTIAL** |
| `followConfirm` | registry key exists | toggle/registry state only; no follow action controller | **PARTIAL** |

## Remaining visible UI features without end-to-end services

The Settings UI exposes additional rows that do not have a complete controller/service/provider/result path in the current Host. They must not be presented as completed Runtime features.

| UI group | Feature IDs | Missing end-to-end component | Status |
|---|---|---|---|
| Profile | `profileStats`, `followerFormat` | no profile service or Host hook | **NOT IMPLEMENTED** |
| Profile | `privateProfile`, `followConfirm` | registry/local toggle exists; no real profile/follow controller | **PARTIAL** |
| Stories | `storyViews`, `anonymousStories`, `storyGradient` | no story provider/host integration; gradient preference only | **PARTIAL** |
| Chats | `videoVoice` | M4A path exists, but no message composer/controller | **PARTIAL** |
| Chats | `undoMessages`, `keepDeleted` | no message storage/controller | **NOT IMPLEMENTED** |
| Downloads | `downloadAvatar`, `downloadComments`, `downloadStickers` | no specific provider/action path | **PROVIDER REQUIRED** |
| Videos | `progressBar`, `likeConfirm`, `showUsername`, `showFlag` | no video Host hook/controller | **NOT IMPLEMENTED** |
| Privacy | `hideAds`, `multiAccount` | no Host integration or system service | **NOT IMPLEMENTED** |
| Privacy | `clearHistory` | local setting only; no complete app lifecycle action | **PARTIAL** |
| Appearance | `liquidNotices`, `liquidOverlays`, `oledKeyboard` | preferences exist; no complete runtime effect on all UI | **PARTIAL** |
| Miscellaneous | `copyText`, `openLinks`, `fastLogout` | no dedicated action/service/result path | **NOT IMPLEMENTED** |

## Error, cancellation, persistence, and security audit

| Area | Evidence | Assessment |
|---|---|---|
| Typed errors | `TiktigerMediaProviderError` covers URL, HTTPS, host, MIME, HTTP, Photos, audio exporter and audio output errors | Present for media path; not every UI toggle has a typed error model |
| Silent failure | several local toggles write state without error return; Share has no completion result; `saveHistory()` ignores encoding/storage failure | Incomplete for full End-to-End standard |
| Cancellation | `Task.checkCancellation()` and `AVAssetExportSession.cancelExport()` exist | Real but device/network/audio test required |
| Persistence | feature keys and history use `NSUserDefaults`; Appearance/Translation use `AppStorage`; Master Switch `enabled` is not persisted | Partial; restart tests required |
| Diagnostics | runtime/symbol/feature events are timestamped, persisted, sanitized, and exportable | Implemented; device export not tested |
| Sensitive data handling | `sanitized()` redacts Authorization, Cookie, Set-Cookie and sensitive query values | Implemented for diagnostics output; no credentials should be placed in test URLs |
| Provider boundary | direct HTTPS provider accepts user-supplied media URL only | Published/page URL resolution remains `PROVIDER REQUIRED` |

## Runtime test plan required for final status

| Test | Required evidence |
|---|---|
| Master Switch | Enable, disable, terminate/relaunch, persistence, and observable effect on dependent actions |
| Appearance | Light/Dark/System or project-supported modes, live refresh, relaunch, all relevant screens |
| Translation | English/Arabic, RTL/LTR, runtime switch, relaunch, no localization keys shown |
| Download | valid/invalid URL, HTTPS-only, HTTP error, MIME error, progress, cancel, retry, cleanup, history |
| Photos | authorized, denied, restricted, save success, save failure |
| M4A | valid video, invalid media, no audio, export success, export failure, cancel, output existence/playability |
| Share | valid file, missing file, user cancellation, completion and cleanup |
| Face ID | success, failure, user/system cancel, unavailable, not enrolled |
| Chats/Favorites Lock | protected state, persistence, relaunch, unlock flow, actual protected screen behavior |
| Runtime Core | real timestamped `dylib_loaded → initializer_executed → core_started → feature_registry_ready → ui_registered → ui_presented` lines from Host/device diagnostics |

## Final source-based status summary

| Feature | Status |
|---|---|
| Master Switch | **PARTIAL** |
| Appearance | **PARTIAL** |
| Translation | **PARTIAL** |
| Diagnostics | **IMPLEMENTED NOT TESTED** |
| Direct HTTPS Download | **IMPLEMENTED NOT TESTED** |
| Published/page URL Download | **PROVIDER REQUIRED** |
| Cancel | **IMPLEMENTED NOT TESTED** |
| Retry | **IMPLEMENTED NOT TESTED** |
| Photos Save | **DEVICE TEST REQUIRED** |
| M4A Extraction | **DEVICE TEST REQUIRED** |
| Share | **PARTIAL** |
| Face ID | **DEVICE TEST REQUIRED** |
| Chats Lock | **PARTIAL** |
| Favorites Lock | **PARTIAL** |

## References

[1]: Tiktiger_1.1/TiktigerHost/TigerHost/ContentView.swift
[2]: Tiktiger_1.1/TiktigerHost/TigerHost/Services/TiktigerMediaDownloadService.swift
[3]: Tiktiger_1.1/TiktigerHost/TigerCore/TigerManager.m
[4]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerRuntimeCoordinator.swift
[5]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerDeviceDiagnostics.swift
[6]: Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/src/TiktigerFeatures.c
[7]: Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/src/TiktigerRuntime.c
[8]: Tiktiger_1.1/Integration/TiktigerHostAdapter.m

المراجع الداخلية: [واجهة Host وUI][1]، [خدمة التنزيل والوسائط][2]، [Persistence المحلي][3]، [RuntimeCoordinator][4]، [Self-Diagnostics والتصدير][5]، [C Feature Registry][6]، [C Runtime milestones][7]، و[Adapter contract][8].
