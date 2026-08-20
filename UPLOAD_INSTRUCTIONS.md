# Tiktiger Clean Runtime Final — Manual Upload Instructions

هذه الحزمة مبنية من commit **8b4d17a** فقط، والـfull SHA هو:

```text
8b4d17a1dda3d70ff61e9bb4efca5fa07245809f
```

لا تشغّل GitHub Actions قبل التأكد أن هذا المحتوى أصبح ظاهرًا على GitHub في commit جديد. لا تستخدم أي commit قديم أو Workflow run سابق.

## 1. فتح المستودع

افتح مستودع GitHub التالي:

```text
https://github.com/anas1213231/-tiktiger-v1.2
```

اختر فرع `main`، ثم استخدم **Add file → Upload files**.

## 2. رفع محتوى الحزمة

ارفع محتوى ZIP إلى جذر المستودع، وليس مجلدًا إضافيًا باسم `Tiktiger_Clean_Runtime_Final_UPLOAD`.

يجب أن تكون البنية النهائية في GitHub مشابهة لما يلي:

```text
.github/workflows/build-tiktiger-ios.yml
Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj/
Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib.xcodeproj/
SOURCE_OF_TRUTH.md
LEGACY_CLEANUP_REPORT.md
UI_SOURCE_MAP.md
FEATURE_VERIFICATION.md
RUNTIME_VERIFICATION.md
KNOWN_ISSUES.md
UPLOAD_INSTRUCTIONS.md
```

النقطة الأهم هي أن Workflow يجب أن يكون بالضبط في هذا المسار:

```text
.github/workflows/build-tiktiger-ios.yml
```

لا تضعه داخل `Tiktiger_1.1/`، ولا تغيّر اسم المشروع أو Scheme أو مسارات Host.

## 3. إنشاء commit الرفع

في خانة رسالة الرفع استخدم الرسالة التالية حرفيًا:

```text
Tiktiger clean runtime final build verification
```

ثم اختر **Commit changes directly to the `main` branch** واضغط **Commit changes**.

## 4. التحقق قبل تشغيل Workflow

بعد اكتمال الرفع، افتح صفحة commit الجديد وتأكد من أن الملفات المرفوعة تظهر تحت commit الجديد، وأن SHA ليس commit قديمًا. تأكد أيضًا من فتح الملف:

```text
.github/workflows/build-tiktiger-ios.yml
```

وتحقق من وجود `runs-on: macos-14` و`workflow_dispatch` وخطوات بناء `TiktigerDylib` و`TiktigerHost`.

## 5. تشغيل GitHub Actions من النسخة الجديدة فقط

افتح تبويب **Actions**، ثم اختر Workflow باسم **Build Tiktiger dylib** أو **Build and Verify Tiktiger 1.1 iOS dylib** بحسب الاسم الظاهر في GitHub. اضغط **Run workflow**، اختر `main`، ثم ابدأ التشغيل.

قبل اعتبار التشغيل صالحًا، افتح تفاصيل run وتأكد أن `Head commit` يطابق commit الرفع الجديد، وليس `ff2ce604` أو أي SHA سابق.

## 6. النتائج المطلوبة

بعد نجاح التشغيل يجب أن يحتوي Artifact على الملفات التالية:

```text
Tiktiger.dylib
build.log
verification.txt
symbol_status.txt
```

لا تُعتبر النتيجة **XCODE VERIFIED** إلا إذا ظهر داخل `build.log` النص:

```text
BUILD SUCCEEDED
```

ويجب أن ينجح `verification.txt` في فحوص Mach-O و`MH_DYLIB` و`arm64` وInstall Name والرموز وSHA-256. وجود ملف باسم `.dylib` أو نجاح static validation وحدهما لا يكفيان.

## 7. Runtime smoke test

بعد نجاح Build وظهور Artifact، لا تُعلن حالة Runtime تلقائيًا. يجب تشغيل Host على بيئة iOS مناسبة وجمع Console log حقيقي يثبت التسلسل التالي:

```text
DYLIB LOADED
INITIALIZER EXECUTED
CORE STARTED
FEATURE REGISTRY READY
UI REGISTERED
UI PRESENTED
```

يجب أن يثبت `UI REGISTERED` و`UI PRESENTED` أن Host view hierarchy أصبحت فعلًا داخل `window` و`superview` وبحدود غير فارغة. constructor وحده لا يكفي لإثبات أي من حالتي UI.

## قاعدة عدم الادعاء

إذا فشل Build أو لم يظهر `BUILD SUCCEEDED` أو لم يتوفر Console log حقيقي من Runtime، فالحالة الصحيحة هي `XCODE BUILD NOT VERIFIED` أو `RUNTIME NOT VERIFIED`. لا تستخدم binary وهميًا ولا تعِد تسمية أي ملف غير صالح إلى `Tiktiger.dylib`.
