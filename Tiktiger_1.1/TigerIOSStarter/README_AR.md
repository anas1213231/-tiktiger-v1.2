# Tiktiger 1.1 — مشروع iOS

هذا المشروع هو نقطة البداية الفعلية لبناء Tiktiger 1.1 على iOS. يحتوي على هدفين: `TigerCore` كـDynamic Framework مبني لـiPhoneOS، و`TigerHost` كتطبيق iOS تجريبي يربط الـFramework ويعرض لوحة Tiktiger.

## الهوية

اسم الأداة داخل الواجهة هو **Tiktiger**، والإصدار التسويقي الأول هو **1.1**. حساب المطور الظاهر في قسم Developer هو `@ucorc`. تمت إضافة شعار Tiktiger وشعار مركز التنزيل إلى موارد التطبيق.

## إعداد البناء الحالي

يستخدم المشروع `SDKROOT = iphoneos` ويدعم `iphoneos` و`iphonesimulator`، والحد الأدنى الحالي هو iOS 15.0. ينتج الهدف `TigerCore` ملف `TigerCore.framework`، بينما ينتج الهدف `TigerHost` تطبيق iOS باسم عرض Tiktiger. قبل التوقيع النهائي يجب تغيير `DEVELOPMENT_TEAM` وBundle ID إلى قيم حساب Apple Developer الفعلية.

## الواجهة الموجودة في الإصدار 1.1

تتضمن الصفحة الرئيسية بطاقة حالة، Master Switch، مركز Downloads، شاشة Diagnostics، أقسام Profile وStories وChats وDownloads وVideos وPrivacy وAppearance، وقسم Developer مع رابط Telegram `@ucorc`. الخيارات تحفظ مفاتيحها محليًا تحت بادئة `tiktiger.feature.`.

مركز التنزيل الحالي منفصل في `TigerHost/Services/TiktigerMediaDownloadService.swift`. ينفذ مسارًا مباشرًا عند تزويده برابط HTTPS وسائط يقدمه المستخدم: يتحقق من المضيف، ينزّل async إلى ملف مؤقت، يحدد MIME/extension، يدعم الإلغاء، Retry داخل الجلسة، وسجلًا محليًا منزوع query/fragment، ثم يطلب صلاحية Photos ويحفظ الفيديو أو الصورة فعليًا. كما يدعم وضع Audio M4A عبر AVFoundation ويحفظ الناتج داخل Documents ويعرض مشاركة النظام. لا يوجد resolver لرابط منشور؛ عند الحاجة تكون الحالة `PROVIDER REQUIRED` حتى توفير endpoint/API مصرح.

## طريقة التشغيل

افتح `TigerIOSStarter.xcodeproj` في Xcode، اختر Scheme `TigerHost`، ثم اختر Simulator أو iPhone حقيقي. عند استخدام جهاز حقيقي يجب اختيار Team صحيح وتعديل Bundle ID. لا يحتوي المشروع على حقن داخل تطبيق طرف ثالث أو تجاوز توقيع أو صلاحيات النظام؛ أي دمج خارجي يجب أن يتم داخل بيئة مصرح بها وبآلية توقيع مناسبة.

## الحالة والمرحلة التالية

تمت إضافة طبقة التنزيل المباشر والحفظ وM4A والمصادقة المحلية وAppearance وTranslation وDiagnostics، مع تصنيف الحالات داخل Diagnostics. يبقى `TiktigerHostAdapter` في حزمة handoff كجسر Objective-C إلى Public API، لكنه غير مربوط داخل Target Starter لأن ملف dylib النهائي والتوقيع يختلفان حسب التطبيق المضيف المصرح. المرحلة التالية هي إضافة Provider/API مصرح لتحويل روابط التطبيق إلى روابط وسائط، ثم ربط hooks أو API المضيف لميزات Profile وStories وChats والخصوصية. لا تُعتبر أي ميزة مضيفة مكتملة حتى تُبنى على macOS، وتُختبر على Simulator وجهاز iPhone حقيقي، وتملك حالات نجاح وفشل وإلغاء وإعادة محاولة.
