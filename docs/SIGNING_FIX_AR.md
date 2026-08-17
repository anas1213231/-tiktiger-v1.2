# إصلاح فشل إعادة التوقيع على TikTok 46.3

## الخطأ المرصود

ظهر في سجل zsign:

```text
Can't find free space of LoadCommands for CodeSignature!
Sign failed!
Failed to sign dylib file: Frameworks/Tiktiger.dylib
```

هذا الخطأ يحدث بعد نجاح حقن `Tiktiger.dylib`، عندما يحاول zsign إضافة `LC_CODE_SIGNATURE` بعد أن أضاف LoadControl أو Injector أوامر تحميل جديدة إلى Mach-O. الملف يعمل كـ Mach-O، لكن رأسه لا يحتوي مساحة حرة كافية لإضافة الأمر الجديد.

## الإصلاح

تم تعديل `Makefile` ليحجز مساحة مسبقة في رأس Mach-O:

```make
Tiktiger_LDFLAGS = ... -Wl,-headerpad_max_install_names -Wl,-headerpad,0x10000
```

`-headerpad_max_install_names` يحجز مساحة لتوسعة أسماء مسارات أوامر التحميل، و`-headerpad,0x10000` يحجز 64 KiB إضافية. هذه المساحة لا تغيّر سلوك الـ Hooks، لكنها تسمح لأدوات الحقن وإعادة التوقيع بإضافة أوامر التحميل والتوقيع لاحقًا.

## ما يجب فعله

بعد رفع commit الإصلاح، انتظر تشغيل GitHub Actions حتى ينجح، ثم حمّل الـ Artifact الجديد. لا تستخدم Artifact القديم قبل الإصلاح؛ لأنه قد يعطي نفس خطأ zsign.

داخل أداة التوقيع، استخدم التسلسل التالي: حقن dylib أولًا، تعديل التبعيات المطلوبة، ثم توقيع Frameworks وdylibs، ثم توقيع التطبيق الرئيسي في النهاية. لا توقّع `Tiktiger.dylib` ثم تعيد تعديل Load Commands بعد التوقيع.

## حدود التوافق

الإصلاح يعالج مساحة Mach-O الخاصة بالتوقيع. لا يضمن وحده أن أسماء TikTok الداخلية في الإصدار 46.3 مطابقة لإصدار 45.x؛ فإذا تم قبول التوقيع لكن لم تعمل ميزة، يجب فحص classes/selectors في Target 46.3 وإضافة المرشحات المناسبة. كما يجب اختبار الميزات على Target مصرح به قبل اعتبارها Runtime Tested.

## التحقق المتوقع

يجب أن يظهر في سجل البناء ما يلي:

```text
Compiling TiktigerHooks.m (arm64)
Compiling TiktigerHooks.m (arm64e)
Linking tweak Tiktiger
Stripping Tiktiger
```

وبعد الحقن والتوقيع يجب ألا يظهر `Can't find free space of LoadCommands for CodeSignature`. إذا ظهر خطأ مختلف، أرفق سجل zsign الجديد لتحديد إن كان متعلقًا بالـ entitlements أو نوع المعمارية أو توافق selectors.
