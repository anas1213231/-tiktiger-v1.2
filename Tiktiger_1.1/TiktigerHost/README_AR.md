# Tiktiger 1.1 — مشروع iOS

هذا المشروع هو نقطة البداية الفعلية لبناء Tiktiger 1.1 على iOS. يحتوي على هدفين: `TigerCore` كـDynamic Framework مبني لـiPhoneOS، و`TiktigerHost` كتطبيق iOS تجريبي يربط الـFramework ويعرض لوحة Tiktiger.

## الهوية

اسم الأداة داخل الواجهة هو **Tiktiger**، والإصدار التسويقي الأول هو **1.1**. حساب المطور الظاهر في قسم Developer هو `@ucorc`. تمت إضافة شعار Tiktiger وشعار مركز التنزيل إلى موارد التطبيق.

## إعداد البناء الحالي

يستخدم المشروع `SDKROOT = iphoneos` ويدعم `iphoneos` و`iphonesimulator`، والحد الأدنى الحالي هو iOS 15.0. ينتج الهدف `TigerCore` ملف `TigerCore.framework`، بينما ينتج الهدف `TiktigerHost` تطبيق iOS باسم عرض Tiktiger. قبل التوقيع النهائي يجب تغيير `DEVELOPMENT_TEAM` وBundle ID إلى قيم حساب Apple Developer الفعلية.

## الواجهة الموجودة في الإصدار 1.1

تتضمن الصفحة الرئيسية بطاقة حالة، Master Switch، مركز Downloads، شاشة Diagnostics، أقسام Profile وStories وChats وDownloads وVideos وPrivacy وAppearance، وقسم Developer مع رابط Telegram `@ucorc`. الخيارات تحفظ مفاتيحها محليًا تحت بادئة `tiktiger.feature.`.

مركز التنزيل الحالي منفصل في `TigerHost/Services/TiktigerMediaDownloadService.swift`. ينفذ مسارًا مباشرًا عند تزويده برابط HTTPS وسائط يقدمه المستخدم: يتحقق من المضيف، ينزّل async إلى ملف مؤقت، يحدد MIME/extension، يدعم الإلغاء، Retry داخل الجلسة، وسجلًا محليًا منزوع query/fragment، ثم يطلب صلاحية Photos ويحفظ الفيديو أو الصورة فعليًا. كما يدعم وضع Audio M4A عبر AVFoundation ويحفظ الناتج داخل Documents ويعرض مشاركة النظام. لا يوجد resolver لرابط منشور؛ عند الحاجة تكون الحالة `PROVIDER REQUIRED` حتى توفير endpoint/API مصرح.

## Runtime Integration

يحتوي Target `TiktigerHost` الآن على `TiktigerRuntimeCoordinator.swift`، ويضمّن `TigerHost/Runtime/Tiktiger.dylib` داخل `Frameworks` عبر PBX Copy Files phase مع `CodeSignOnCopy`. لا يوجد binary داخل المصدر عمدًا؛ يجب نسخ binary iOS arm64 الحقيقي الناتج من مشروع dylib إلى هذا المسار قبل بناء Host. غياب الملف يجب أن يفشل البناء أو يظهر `DYLIB LOADED = FAILED`، ولا يجوز إنشاء placeholder أو إعادة تسمية binary macOS.

عند بدء `ContentView` يستدعي coordinator `dlopen` ثم `dlsym` على runtime APIs، ويعرض حالات `VERIFIED/FAILED` للتحميل وinitializer وCore وFeature registry وUI registration وUI presentation. مفاتيح الميزات الموجودة في registry تمر إلى `tt_set_feature_enabled`، بينما إعدادات المضيف المحلية تبقى في `TigerManager` ولا تتظاهر بأنها hooks داخل تطبيق آخر.

## طريقة التشغيل

1. ابنِ `Tiktiger.dylib` الحقيقي على macOS/iPhoneOS.
2. انسخه إلى `TigerHost/Runtime/Tiktiger.dylib`.
3. افتح `TiktigerHost.xcodeproj`، اختر Scheme `TiktigerHost`، ثم اختر Simulator أو iPhone حقيقي.
4. عند استخدام جهاز حقيقي اختر Team صحيحًا وعدّل Bundle ID ووقّع التطبيق والمكتبة وفق إعداداتك.
5. افتح Diagnostics وتحقق من ظهور `[TiktigerRuntime]` ومن انتقال كل milestone إلى `VERIFIED`.

لا يحتوي المشروع على حقن داخل تطبيق طرف ثالث أو تجاوز توقيع أو صلاحيات النظام؛ أي دمج خارجي يجب أن يتم داخل تطبيق تملكه أو بيئة مصرح بها وبآلية توقيع مناسبة.

## الحالة والحدود

تمت إضافة طبقة التنزيل المباشر والحفظ وM4A والمصادقة المحلية وAppearance وTranslation وRuntime Diagnostics. يبقى Provider/API مصرح مطلوبًا لتحويل روابط التطبيق إلى روابط وسائط، كما أن ميزات Profile وStories وChats والخصوصية داخل تطبيق مضيف طرف ثالث تحتاج APIs أو Integration خاصة بذلك المضيف. لا تُعتبر أي ميزة Runtime مكتملة حتى تُبنى بالـbinary الصحيح وتُختبر على Simulator وجهاز iPhone حقيقي وتملك logs وحالات نجاح وفشل وإلغاء وإعادة محاولة.
