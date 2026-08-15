# تقرير التحليل الثابت لتويكي TikTok: ASDTweak وShowrohat

**إعداد:** Manus AI  
**تاريخ التحليل:** 15 أغسطس 2026  
**نطاق العمل:** تحليل ثابت للملفين المرفقين، من دون تشغيلهما أو تحميلهما داخل TikTok أو تنفيذ كود منهما.

## 1. الملخص التنفيذي

يُظهر التحليل أن الملفين مكتبتان ديناميكيتان بصيغة **Mach-O 64-bit arm64e** مخصصتان لبيئة iOS، ومربوطتان اختيارياً داخل `AAAASingularity.framework` في تطبيق TikTok ذي المعرّف `com.zhiliaoapp.musically` والإصدار `45.6.0`. التويكان مختلفان جذرياً في الحجم والسطح الوظيفي.

`ASDTweak.dylib` هو مكوّن كبير متعدد الوظائف؛ إذ يحتوي على بنية Objective‑C واسعة، وكلاسات عديدة للكاميرا والصوت وحقن الإطارات والتنزيلات وواجهات HUD وعناصر تحكم مثل TapBot وتكرار الرسائل، مع اعتماد مباشر على أطر الوسائط والرسوميات والصور وSubstrate وCephei. أما `Showrohat.dylib` فهو مكوّن صغير ومحدد الوظيفة، يتمحور حول نافذة Overlay وزر عائم قابل للسحب، مع حفظ موضع الزر لكل شاشة عبر `NSUserDefaults` وفتح رابط Telegram ثابت.

> **الاستنتاج الأهم:** ASDTweak يبدو كحزمة أدوات/واجهة تحكم واسعة تتدخل في مسارات الكاميرا والميكروفون والصوت والفيديو والتفاعل، بينما Showrohat يبدو كواجهة عائمة بسيطة ذات وظيفة ترويجية/اختصار خارجي، وليس كتويك وسائط أو شبكة متقدم.

## 2. المدخلات وسلامة الجرد

تم فك ضغط الأرشيفين في مجلد عمل مستقل. احتوى كل أرشيف على ملف dylib وملف `manifest.json` فقط؛ ولم تظهر ملفات plist مستقلة أو صور منفصلة أو موارد مجاورة خارج المكتبتين.

| العنصر | ASDTweak | Showrohat |
|---|---:|---:|
| اسم الأرشيف | `TikTok-Plugin-ASDTweak.dylib-20260813-224225.zip` | `TikTok-Plugin-Showrohat.dylib-20260813-224236.zip` |
| SHA-256 للأرشيف | `d4e0cd49371e16990ca0ceb9512bbdbe5dccfe5732a7b27a319670b396a3b704` | `71a52e4ae7e16066452df183cf0bdcbeb3b6a5064b97ad461e0df121533a7987` |
| الملف المفكوك | `ASDTweak.dylib` | `Showrohat.dylib` |
| الحجم | 604,803 بايت | 176,481 بايت |
| نوع الملف | Mach-O 64-bit arm64e dylib | Mach-O 64-bit arm64e dylib |
| SHA-256 للـ dylib | تم حفظه في ملفات التحليل الخام المرفقة | تم حفظه في ملفات التحليل الخام المرفقة |
| موارد مجاورة | `manifest.json` فقط | `manifest.json` فقط |

يؤكد كل manifest أن الحالة `linked`، وأن الربط مع المضيف `framework:AAAASingularity.framework` اختياري (`weak: true`) ولا يستبدل ملفاً قائماً (`replacesExisting: false`). كما يذكر أن المشروع الأصلي هو TikTok، الإصدار `45.6.0`، والاسم الأصلي لحزمة IPA هو `TikTok_CameraFake_new.ipa`.

## 3. بنية Mach-O

كلا الملفين يبدأان بترويسة Mach-O 64-bit ذات magic value `0xFEEDFACF`، ونوع الملف `DynamicLibrary`. كلاهما arm64/arm64e مع أعلام ربط ديناميكي وTwo-Level Namespace وبدون undefined symbols غير محلولة من منظور الملف النهائي. الفرق البنيوي واضح في عدد أوامر التحميل والأقسام.

| المقياس البنيوي | ASDTweak | Showrohat |
|---|---:|---:|
| عدد أوامر التحميل | 45 | 24 |
| حجم أوامر التحميل | 5,928 بايت | 3,256 بايت |
| عدد الأقسام المستخرجة | 35 | 25 |
| قسم الكود `__text` | موجود وكبير نسبياً | موجود وأصغر بكثير |
| أقسام Objective‑C | واسعة ومتعددة | موجودة ولكن محدودة |
| `__objc_classlist` | 0x168 بايت، أي مساحة لعدد كبير من مراجع الكلاسات | 0x10 بايت، أي عدد محدود جداً |
| `__objc_methname` | 0x77ac بايت | 0x662 بايت |
| `__objc_classname` | 0x588 بايت | 0x2d بايت |
| `__objc_methtype` | 0x1301 بايت | 0xe6 بايت |
| أقسام بيانات Objective‑C | classlist، protocol list، ivars، const، selrefs، data وغيرها | classlist، const، selrefs، classrefs، ivar، data |

تتضمن ASDTweak أقساماً إضافية تدل على تعقيد أعلى، مثل `__auth_stubs` و`__auth_got` و`__auth_ptr` الملائمة لبيئة Pointer Authentication، إضافة إلى أقسام `__objc_arraydata` و`__objc_arrayobj` و`__objc_dictobj` و`__cfstring`. يحتوي Showrohat على البنية الأساسية نفسها تقريباً ولكن من دون هذه الكثافة في الجداول والبيانات.

تم العثور على أمر `LC_UUID` في الملفين. كما تظهر داخل النصوص آثار بيانات توقيع/تغليف Apple وTrollStore وكتل plist تحتوي على `cdhashes`. هذه العناصر لا تثبت وظيفة تشغيلية داخل التويك؛ والأرجح أنها بقايا توقيع أو تغليف من بيئة التثبيت. لم يظهر من الفحص الثابت تشفير للحمولة أو ضغط داخلي إضافي داخل dylib، لكن لا يمكن من هذا التحليل وحده التحقق من صحة التوقيع على جهاز iOS.

## 4. الرموز والكلاسات والميثودات

### 4.1 ASDTweak

يحتوي ASDTweak على نحو **45 كلاس Objective‑C معرّفاً** في جدول الرموز، إضافة إلى عدد كبير من الرموز المستوردة. من أبرز الكلاسات المعرّفة:

| المجال | الكلاسات الدالة |
|---|---|
| الكاميرا والالتقاط | `ASDFakeCameraManager`, `ASDFakeCameraControlPanel`, `ASDFakeCapturePhoto`, `ASDFrameInjector` |
| الصوت والميكروفون | `ASDAudioInjector`, `ASDFakeVoiceHandler`, `ASDFakeVoicePicker`, `ASDFakeVoiceOverlayWindow`, `ASDMicShortcutTarget` |
| الواجهات العائمة والتحكم | `ASDLiveHUDWindow`, `ASDPassthroughView`, `ASDPassthroughWindow`, `ASDTapBotWidget`, `ASDTapBotPassthroughView`, `ASDTapBotPassthroughWindow` |
| التكرار والرسائل | `ASDRepeatMessageWidget`, `ASDRepeatMsgPassthroughView`, `ASDRepeatMsgPassthroughWindow` |
| التنزيلات | `ASDDownload`, `ASDMultipleDownload` |
| إعدادات وواجهة الميزات | `ASDFeaturesViewController`, `ASDFeatureSection`, `ASDFeatureRow`, `ASDSwitchTableCell`, `ASDButtonTableViewCell`, `ASDIManager`, `ASDLocalization` |
| واجهة التقدم | مجموعة `JGProgressHUD`، بما فيها مؤشرات Ring وPie وFade وSuccess |
| مكونات إضافية | `SecurityViewController`, `SettingsViewController`, `_AladImgRec`, `_AladLblRec` |

تظهر أيضاً دوال عامة بأسماء مباشرة، من بينها `ASDForceFakeCameraOn` و`ASDToggleForceFakeCamera` و`ASDFakeMicReplaceOn` و`ASDToggleFakeMicReplace` و`ASDLiveHUDShow` و`ASDLiveHUDHide` و`ASDHookDiagnosticsSnapshot`. هذه الأسماء قوية الدلالة على وجود مفاتيح تشغيل للكاميرا الوهمية واستبدال الميكروفون وإظهار/إخفاء HUD، وعلى وجود مسار تشخيص للـ hooks.

تظهر أسماء ميثودات كثيرة مرتبطة بتحويل الفيديو والصوت، منها `getPixelBuffer:` و`setVideoOutput:` و`imageToLoopingVideo:completion:` و`togglePlayPause` و`playURL` و`setVolume:` و`setTapInterval:` و`pixelBufferPool` و`cachedStillCIImage`. كما تظهر ميثودات AVFoundation وCoreMedia الخاصة بـ `CMSampleBuffer` و`CVPixelBuffer` وكتابة H.264/MP4؛ وهذا ينسجم مع حقن الإطارات أو معالجة فيديو/صوت بدلاً من مجرد تغيير واجهة.

تظهر كذلك ميثودات تنزيل كاملة عبر `NSURLSession`، مثل `URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:` و`URLSession:downloadTask:didFinishDownloadingToURL:` و`URLSession:dataTask:didReceiveData:`، مع واجهة تقدم وحقول مثل `totalDownloads` و`progressHUD` و`workingURL`. لذلك توجد مؤشرات قوية على دعم تنزيل ملفات أو وسائط داخل التويك.

### 4.2 Showrohat

يحتوي Showrohat على **كلاسين معرّفين فقط**: `ShowrohatController` و`ShowrohatOverlayWindow`، مع metaclass المقابل. أسماء الميثودات توضح الوظيفة بدقة أكبر من مجرد أسماء الرموز:

| السلوك | الأدلة الاسمية |
|---|---|
| إنشاء نافذة عائمة | `initWithWindowScene:`, `setWindow:`, `setWindowLevel:`, `setRootViewController:` |
| زر عائم | `floatButton`, `setFloatButton:`, `setImage:`, `setFrame:`, `setUserInteractionEnabled:` |
| السحب والنقر | `handlePan:`, `handleTap:`, `addGestureRecognizer:`, `translationInView:` |
| ضبط حدود الحركة | `clampCenter:inBounds:`, `reclampSoon`, `saveCenter:`, `savedCenterForScreen:` |
| حفظ الموضع | `standardUserDefaults`, `doubleForKey:`, `setDouble:forKey:` |
| دعم تعدد الشاشات/المشاهد | `connectedScenes`, `activeWindowScene`, `currentDevice`, `beginGeneratingDeviceOrientationNotifications` |
| فتح الرابط | `openTelegram`, `openURL:options:completionHandler:` |

لا تظهر في Showrohat رموز أو أقسام خاصة بالكاميرا أو الصوت أو الفيديو أو `NSURLSession` للتنزيلات. سطحه الوظيفي هو UIKit/CoreGraphics/QuartzCore مع Foundation وNSUserDefaults وNSNotificationCenter، وهو ما يدعم تصنيفه كتويك Overlay خفيف.

## 5. المكتبات والأطر المرتبطة

### 5.1 ASDTweak

يرتبط ASDTweak مباشرة بعدد كبير من الأطر. قائمة الاعتمادات تشمل `CydiaSubstrate` و`libobjc` و`libSystem` و`libc++`، إضافة إلى Foundation وCoreFoundation وUIKit وCoreGraphics وQuartzCore. وتشمل أيضاً Photos وPhotosUI وCoreServices وSystemConfiguration وSafariServices وSecurity وPreferences وCephei وCepheiPrefs وCepheiUI وLocalAuthentication وUniformTypeIdentifiers.

سطح الوسائط واسع جداً: `AVFoundation` و`AVFAudio` و`CoreMedia` و`CoreVideo` و`MediaToolbox` و`AudioToolbox` و`CoreImage`. كما يظهر رمز ضعيف `MSHookMessageEx` من CydiaSubstrate، ما يؤكد وجود آلية hook متوقعة، مع التنبيه إلى أن وجود الرمز لا يثبت وحده أي hook بعينه أو توقيته.

### 5.2 Showrohat

يرتبط Showrohat بمجموعة صغيرة: CydiaSubstrate، `libobjc.A.dylib`، Foundation، CoreFoundation، UIKit، CoreGraphics، QuartzCore، `libc++.1.dylib` و`libSystem.B.dylib`. عدم وجود AVFoundation أو CoreMedia أو CoreVideo أو MediaToolbox أو Photos أو Security أو Cephei يثبت الفرق الكبير في النطاق التقني بين الملفين.

## 6. النصوص والموارد المضمّنة

### 6.1 Showrohat

يحتوي قسم `__cstring` على رابط نصي صريح:

> `https://t.me/Altheeb_store/12185`

كما يحتوي على مفتاحي تفضيلات:

> `com.showrohat.floatbtn.x`  
> `com.showrohat.floatbtn.y`

وهذا يطابق ميثودات `saveCenter:` و`savedCenterForScreen:`، ويؤكد أن الزر يحفظ إحداثياته. يحتوي الملف أيضاً على سلسلة Base64 تبدأ بـ `iVBORw0...` وتنتهي بتوقيع PNG المعتاد `...CYII=`؛ وهي مورد صورة/أيقونة مضمّن داخل المكتبة، وليس ملف PNG منفصلاً.

### 6.2 ASDTweak

تكشف النصوص وأسماء الميثودات عن مجموعة واسعة من الوظائف: `asd_pickCameraButton` و`asd_pickImageButton` و`asd_pickURLButton` و`asd_saveAvatar` و`asd_showResult:`، إضافة إلى `hideAds` و`voiceOverEnabled` و`tapTool` و`setTapInterval:` و`playURL` و`h264URL` و`stillImageJPEG`. توجد أيضاً مفاتيح لغات `ASDLanguageArabic` و`ASDLanguageChinese` و`ASDLanguageEnglish` و`ASDLanguageRussian` و`ASDLanguageVietnamese`، ما يثبت وجود طبقة توطين متعددة اللغات.

تظهر داخل ASDTweak بقايا نصوص شهادات Apple وTrollStore وكتل plist ذات المفتاح `cdhashes`. لا توجد في النصوص التي جرى استخراجها دلالة مؤكدة على عنوان خادم تحليلات أو API خاص بالتويك؛ لكن وجود `NSURLSession` لا يسمح بنفي كل اتصال شبكي، بل يثبت فقط وجود كود قادر على تنفيذ عمليات URL/تنزيل.

## 7. تقدير الوظائف والميزات

### ASDTweak

الوظيفة الأساسية المرجحة هي توفير لوحة ميزات داخل TikTok للتحكم في مسارات إدخال الوسائط والتفاعل. المؤشرات الأقوى هي الكاميرا الوهمية، حقن إطارات الفيديو، التقاط صورة، استبدال الميكروفون أو حقن الصوت، تشغيل فيديو/صورة كمدخل، عناصر HUD عائمة، تنزيلات متعددة، تكرار رسائل، وTapBot أو أدوات تفاعل آلي. كما توجد طبقة إعدادات وتفضيلات وتوطين وواجهة تقدم.

لا يمكن من التحليل الثابت وحده تأكيد شروط التفعيل أو كل الأصناف المستهدفة أو أن كل الكلاسات تُستخدم فعلاً في كل جلسة. كذلك لا يمكن الجزم بأن كل وظيفة تعمل مع الإصدار 45.6.0 من TikTok من دون تشغيل مضبوط ومراقبة سلوكية على جهاز اختبار معزول.

### Showrohat

الوظيفة الأساسية هي إنشاء نافذة Overlay فوق واجهة التطبيق، وإضافة زر عائم يحمل أيقونة مضمّنة. الزر يقبل السحب والنقر، ويحفظ موضعه باستخدام `NSUserDefaults`، ويعيد ضبطه ضمن حدود الشاشة عند تغير الاتجاه أو المشهد. النقر يستدعي `openTelegram` ويفتح الرابط الثابت في Telegram.

## 8. المقارنة التقنية

| البعد | ASDTweak | Showrohat | التفسير |
|---|---:|---:|---|
| الحجم | 604,803 بايت | 176,481 بايت | ASDTweak أكبر بنحو 3.43 مرات |
| أوامر التحميل | 45 | 24 | ASDTweak أكثر تعقيداً في الربط والتغليف |
| الأقسام | 35 | 25 | كثافة بيانات وكود أعلى في ASDTweak |
| الكلاسات المعرفة | نحو 45 | 2 | ASDTweak حزمة متعددة المكونات؛ Showrohat وحدة صغيرة |
| مساحة أسماء الميثودات | 0x77ac | 0x662 | جدول ASDTweak أكبر بنحو 46 مرة تقريباً |
| المكتبات المباشرة | نحو 30 اسماً في التفريغ | 9 | ASDTweak يعتمد على وسائط وصور وتفضيلات وأدوات hooks |
| AVFoundation/CoreMedia/CoreVideo | موجودة | غير موجودة | مؤشرات قوية على معالجة/حقن الوسائط في ASDTweak |
| شبكة/تنزيل | `NSURLSession` وواجهات تنزيل | رابط Telegram ثابت فقط | ASDTweak أكثر اتساعاً؛ Showrohat اختصار خارجي |
| موارد مضمّنة | بيانات وواجهات ونصوص كثيرة | أيقونة PNG Base64 | Showrohat يستخدم مورداً بصرياً واحداً واضحاً |
| المخاطر التشغيلية المحتملة | أعلى بسبب hooks والوسائط والصلاحيات | محدودة نسبياً إلى Overlay وفتح URL | هذا تقدير بنيوي لا حكم أمني نهائي |

## 9. الحدود والاستنتاجات الأمنية

هذا التقرير **تحليل ثابت** وليس تقرير سلوك ديناميكي. لم يتم تشغيل المكتبات، ولم يتم ربطها بتطبيق TikTok، ولم تُفحص اتصالات فعلية أو تغييرات ملفات أو عمليات interposition وقت التشغيل. أسماء الرموز والنصوص والاعتمادات أدلة قوية على القدرات المحتملة، لكنها لا تثبت أن كل مسار يُنفذ فعلاً أو أن كل وظيفة آمنة أو متوافقة.

يستحق ASDTweak فحصاً ديناميكياً معزولاً إذا كان الهدف تقييم السلامة: يجب مراقبة hooks، والوصول إلى الكاميرا والميكروفون والصور، والاتصالات الشبكية، وإنشاء الملفات، وسلوك تنزيل الوسائط، ومحاولات تجاوز قيود التطبيق. كما ينبغي مطابقة UUID وCode Directory وentitlements مع نسخة موثوقة من المصدر قبل استخدامه.

أما Showrohat، فالمؤشر الأكثر مباشرة هو الرابط الثابت إلى Telegram. ينبغي التعامل معه كاتصال خارجي مقصود عند النقر، والتحقق من الرابط قبل نشر المكتبة أو استخدامها في بيئة إنتاجية. وجود بقايا توقيع/شهادات أو plist داخل strings لا يكفي وحده للحكم على سلامة المصدر أو أصالته.

## 10. الملفات الداعمة التي تم إنتاجها

أُرفقت مع التقرير حزمة أدلة التحليل الخام، وتشمل جرد الملفات، manifests، مخرجات LLVM للرؤوس والأقسام والـ load commands والـ disassembly، قوائم الرموز والمكتبات، وتفريغ أقسام Objective‑C والنصوص. هذه الملفات مفيدة لإعادة التدقيق أو لإكمال التحليل الديناميكي لاحقاً.

## المراجع

[1]: https://github.com/llvm/llvm-project/tree/main/llvm/tools/llvm-objdump "LLVM llvm-objdump documentation and source"

[2]: https://developer.apple.com/documentation/kernel/mach-o "Apple Mach-O documentation"

[3]: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/ "Apple Objective-C Runtime Programming Guide"

[4]: https://developer.apple.com/documentation/avfoundation "Apple AVFoundation documentation"

[5]: https://developer.apple.com/documentation/uikit "Apple UIKit documentation"
