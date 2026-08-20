# TiktigerDylib — حزمة بناء iOS 1.1

هذه الحزمة مخصصة لبناء **Tiktiger.dylib** فعلي باستخدام Xcode وApple iPhoneOS SDK، مع نواة C صغيرة قابلة لإعادة الاستخدام. المكتبة لا تحتوي آلية حقن داخل تطبيق طرف ثالث ولا تتجاوز توقيع Apple؛ تظهر الواجهة وتشغل خدمات Photos/AVFoundation/LocalAuthentication عبر Adapter داخل تطبيق مضيف مصرح.

## الناتج المطلوب

بعد نجاح البناء على Mac ستجد الملف هنا:

`BuildOutput/Tiktiger.dylib`

الـTarget مضبوط على:

- SDK: `iphoneos`
- Architecture: `arm64`
- Mach-O Type: `mh_dylib`
- Product: `Tiktiger.dylib`
- Release: `1.1`
- Deployment Target: iOS 15+
- Install Name: `@rpath/Tiktiger.dylib`

## الهوية الجديدة

تمت إضافة:

- `Branding/Tiktiger_Logo_Round.png` — الشعار الدائري الجديد.
- `Branding/Tiktiger_Download_Icon_256.png` — سهم تنزيل صغير بحدود شفافة مناسب للواجهة.

في مشروع التطبيق المضيف، استخدم الشعار داخل بطاقة Tiktiger وقسم المطور `@ucorc`. استخدم سهم التنزيل بحجم واجهة يقارب 72 نقطة داخل شارة 96 نقطة، ولا تعرض صورة 3464px الأصلية مباشرة في الواجهة.

## Public API الحالية

يوجد السطح العام في `TiktigerDylib/include/Tiktiger.h`، والتنفيذ مقسم بين `Tiktiger.c` و`TiktigerFeatures.c`.

تتضمن API اسم المنتج والإصدار، حالة التفعيل، عداد التشخيص، uppercase/checksum، إدارة مفاتيح الميزات، التحقق من HTTPS دون تنفيذ شبكة، تنظيف اسم الملف، مراحل التنزيل، وdiagnostics JSON لا يحتوي أسرارًا أو بيانات مستخدم.

مفاتيح الميزات الحالية تشمل `downloadMedia`, `downloadStories`, `downloadAudio`, `readChats`, `ghostTyping`, `lockChats`, `lockFavorites`, `privateProfile`, `liquidControls`, و`followConfirm`.

## أسهل طريقة للبناء

على Mac:

1. فك الضغط.
2. افتح Terminal داخل مجلد `Xcode_Dylib_Project`.
3. شغّل `chmod +x BUILD_TIKTIGER.command Scripts/*.sh` إذا لزم.
4. شغّل `./BUILD_TIKTIGER.command`.

السكربت يبني Release لـarm64 باستخدام `iphoneos`، ينسخ الناتج إلى `BuildOutput/Tiktiger.dylib`، ثم يشغل `Scripts/verify_dylib.sh`. التحقق fail-closed ويوقف العملية إذا غابت أدوات `file` أو `lipo` أو `otool` أو `nm`، ثم يراجع Mach-O وarm64 و`MH_DYLIB` و`@rpath/Tiktiger.dylib` والرموز العامة. تُحفظ النتائج في `BuildLogs/latest-build.log` و`BuildLogs/verification.txt` و`BuildLogs/Tiktiger.dylib.sha256`.

## ما يلزم للمضيف

الـdylib لا تقوم وحدها بعرض SwiftUI أو طلب صلاحية Photos أو تشغيل Face ID؛ هذه وظائف UIKit/SwiftUI/Photos/AVFoundation/LocalAuthentication داخل التطبيق المضيف. يوجد في المضيف Service منفصل للتنزيل المباشر عبر HTTPS مع cancellation وretry/history، بينما يبقى Adapter Objective-C جسرًا رفيعًا إلى Public API ويحتاج ربطًا صريحًا في Target مصرح به.

مزود تحويل رابط المنشور إلى رابط وسائط لم يُضمّن كـendpoint سري. يجب توفير Provider مصرح أو API خاص بك عبر Adapter، وعدم وضع رموز أو مفاتيح وصول داخل المصدر.

## entitlements والتوقيع

المكتبة `.dylib` نفسها لا تحتاج entitlements مستقلة لهذا القالب. صلاحيات iOS وentitlements والتوقيع تخص التطبيق المضيف وملف provisioning الخاص به. لا تضف صلاحيات عشوائية لمعالجة خطأ توقيع، ولا تدمج المكتبة إلا داخل تطبيق تملكه أو ضمن بيئة اختبار مصرح بها.
