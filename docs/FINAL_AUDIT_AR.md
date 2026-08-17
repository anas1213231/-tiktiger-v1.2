# التدقيق النهائي لنسخة Tiktiger v1.2 المعدلة

## النطاق

تم تحديث نسخة المستودع السابقة مع الحفاظ على بنيتها الأصلية ذات الملفات الثلاثة الأساسية. أضيفت الميزات الأربع المطلوبة، وتم دمج الصور الثلاث المعتمدة في موارد Theos، مع تحديث GitHub Actions لاستخراج `Tiktiger.dylib` كـ Artifact.

## الميزات

| الميزة | مفتاح الحفظ | Hook أو مسار التنفيذ | حالة الفحص المصدرية |
|---|---|---|---|
| Anonymous Profile Visits | `anonymousProfiles` | `TTKProfileViewsVisitor` مع ثلاثة selectors مرشحة | ناجح |
| Keep Story Unseen | `unseenStories` | `TTKStoryManager markStoryReaded:` و`TTKStoryMarkReadService markAsRead:` | ناجح |
| Keep Messages Unseen | `unreadMessages` | `AWEIMMessageReadComponent` لمسارات read-sync فقط | ناجح |
| Hide Typing | `hideTyping` | مرشحات مستقلة لـ `sendTyping` و`sendTypingStatus:` | ناجح مصدرية، يحتاج Runtime للتحقق من الاسم الفعلي |

كل Hook يستخدم `TTInstallCheckedHook`، الذي يفحص وجود class وselector قبل تسجيل `MSHookMessageEx`. كل original IMP في Hide Typing منفصل لكل class/selector حتى لا يحصل تداخل بين المسارات.

## الصور والواجهة

| الملف | المصدر | الاستخدام | حالة الإدراج |
|---|---|---|---|
| `assets/tiktiger-download.png` | الصورة المرفقة ذات سهم التحميل | الزر العائم وأيقونات التحميل | مدرج في Makefile ويُستخدم أولًا من bundle |
| `assets/tiktiger-main.png` | صورة شعار Tiktiger المرفقة | شعار الأداة | مدرج في Makefile ويُستخدم أولًا من bundle |
| `assets/tiktiger-developer-cover.jpg` | صورة الفهد المرفقة | غلاف المطور في رأس Settings | مدرج في Makefile ومربوط بـ `TTDeveloperCover()` |

تم تحسين الصور PNG إلى حجم أقصى يقارب 1024px مع الحفاظ على RGBA، وتحويل صورة الغلاف إلى JPEG محسّن بحجم 832×1216. لم يتم تغيير محتوى الصور دلاليًا؛ تمت معالجة الحجم والصيغة فقط لتناسب الحزمة.

## GitHub Actions

يقوم workflow في `.github/workflows/build.yml` بما يلي:

1. يعمل على `macos-14`.
2. يثبت Theos و`ldid` و`dpkg` وiPhoneOS SDK.
3. ينشئ CydiaSubstrate compatibility stub المطلوب للبناء الحالي.
4. ينفذ `make clean` ثم `make package FINALPACKAGE=1`.
5. يبحث عن `Tiktiger.dylib` ويوقف workflow إذا لم يجده.
6. يتحقق من الملف باستخدام `file` و`otool -L` وSHA-256.
7. يرفع `Tiktiger.dylib` وملف `.deb` وسجلات البناء كـ Artifact.

## نتائج التحقق

تم تشغيل `tools/verify_privacy_merge.py` بعد إضافة الصور وتحديث الواجهة، وكانت النتيجة:

```text
Errors: 0
- None
```

كما نجح `git diff --check`. أما البناء المحلي في بيئة Linux الحالية فلم يبدأ بسبب غياب Theos، وظهر الخطأ:

```text
Makefile:11: /tweak.mk: No such file or directory
```

هذا لا يعني أن workflow على macOS سيفشل، لكنه يعني أن نجاح الـ dylib النهائي لا يمكن إثباته إلا بعد تشغيل GitHub Actions فعليًا.

## قائمة مراجعة ما قبل الرفع

| بند | الحالة |
|---|---|
| الميزات الأربع موجودة في Settings القديم | نعم |
| لكل ميزة مفتاح مستقل | نعم |
| Hooks محمية بفحص class/selector | نعم |
| عدم إعادة استخدام original IMP بين classes مختلفة | نعم |
| شعار الأداة مضاف | نعم |
| سهم التحميل مضاف | نعم |
| غلاف المطور مضاف | نعم |
| غلاف المطور مدرج في `Tiktiger_RESOURCE_FILES` | نعم |
| workflow يستخرج `Tiktiger.dylib` ويفشل إذا لم يجده | نعم |
| workflow يرفع logs وSHA-256 | نعم |
| بناء macOS فعلي | ينتظر تشغيل GitHub Actions |
| اختبار Runtime على TikTok target مصرح | ينتظر جهاز/Target مصرح |

## الخلاصة

النسخة المحلية جاهزة للرفع إلى GitHub من ناحية المصدر والموارد والـ workflow. لا يوجد ادعاء بأن الـ dylib أصبح Runtime Tested قبل نجاح GitHub Actions واختباره على Target مصرح؛ هذا هو الحد المهني الصحيح للتأكد من عدم تسليم ملف غير صالح أو Hook غير متوافق.
