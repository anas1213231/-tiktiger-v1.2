# Tiktiger Runtime Binary

ضع هنا **binary حقيقيًا** باسم `Tiktiger.dylib` بعد نجاح بناء مشروع `Xcode_Dylib_Project` على macOS/iPhoneOS:

```text
TigerHost/Runtime/Tiktiger.dylib
```

مشروع `TigerHost` يضمّن الملف إلى `Frameworks` عبر PBX Copy Files phase ويوقّعه عبر `CodeSignOnCopy`. لا تستخدم ملفًا نصيًا أو binary macOS أو dSYM أو binary غير موثوق، ولا تعِد تسمية ملف غير صالح إلى `Tiktiger.dylib`.

عند تشغيل المضيف، يقوم `TiktigerRuntimeCoordinator` باستدعاء `dlopen` ثم `dlsym` على runtime probes، ويعرض `VERIFIED` فقط لكل milestone شوهد فعليًا. إذا غاب هذا الملف سيفشل Host build أو تظهر حالة `DYLIB LOADED = FAILED` بدل نجاح مضلل.
