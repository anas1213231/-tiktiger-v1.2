# Tiktiger 1.1 — Source of Truth

هذا المستند يحدد النسخة الوحيدة المعتمدة لمشروع **Tiktiger 1.1** بعد Legacy Dependency Audit وSafe Rename. الهوية المعتمدة هي Tiktiger، والمطور الظاهر في الواجهة هو **@ucorc** على Telegram. لا تُعد أي نسخة سابقة أو اسم بديل مصدرًا للميزات أو الأصول أو إعدادات البناء.

## الشجرة النشطة

| العنصر | المسار أو الاسم النشط | الحالة |
|---|---|---|
| مشروع iOS المضيف | `Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj` | معتمد |
| Host target | `TiktigerHost` | معتمد |
| Host scheme | `TiktigerHost.xcscheme` | معتمد |
| Host product | `TiktigerHost.app` | معتمد |
| Core target | `TigerCore` داخل مشروع Host | معتمد، ولم يُعدّل اسمه لأنه ليس Legacy dependency |
| مشروع dylib | `Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib.xcodeproj` | معتمد |
| dylib scheme/target | `TiktigerDylib` | معتمد |
| مصدر C | `Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/src/` | معتمد |
| واجهة SwiftUI | `Tiktiger_1.1/TiktigerHost/TigerHost/ContentView.swift` | معتمدة |
| Runtime coordinator | `Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerRuntimeCoordinator.swift` | معتمد |
| Runtime binary input | `TigerHost/Runtime/Tiktiger.dylib` داخل Host | يُنسخ من BuildOutput في CI؛ لا يوجد binary committed عمدًا |

> بقاء مجلد source group الداخلي `TigerHost` وملف `TigerHost.entitlements` مقصود للحفاظ على مسارات PBX الحالية. لا يحتوي أي منهما على مرجع TigerIOSStarter أو FeatureKit أو VibeTok، وقد اجتازا فحص الملفات والمراجع النشطة.

## قواعد الاعتماد

المصدر النشط للواجهة هو `ContentView.swift` مع ملفات الخدمة وRuntime coordinator المدرجة في Compile Sources داخل target `TiktigerHost`. المصدر النشط للـdylib هو مشروع `TiktigerDylib.xcodeproj` وملفات `Tiktiger.c` و`TiktigerFeatures.c` و`TiktigerRuntime.c` وPublic header `Tiktiger.h`. الأصول الحالية هي `tiktiger_logo.png` و`download_arrow.png` و`Assets.xcassets/TiktigerIcon.appiconset`.

تم تحديث project file وSchemes وWorkflow وvalidators لتشير إلى `TiktigerHost`. حُفظت PBX UUIDs كما هي، ولم تُنشأ UUIDs جديدة أثناء Safe Rename. يعتمد CI على `tools/validate_legacy_active_references.py` لإيقاف البناء إذا ظهر اسم Legacy داخل PBX أو Scheme أو Workflow أو Compile Sources أو Resources أو Embed phases.

## حدود الإثبات

البيئة الحالية Linux ولا تحتوي macOS أو Xcode أو iOS SDK، لذلك لا يجوز وصف المشروع بأنه **XCODE VERIFIED** في هذه الحزمة. الإثبات الحقيقي للبناء هو نجاح Workflow على macOS وظهور `BUILD SUCCEEDED`، ثم نجاح فحوص `file` و`lipo` و`otool` و`nm` وSHA-256 على binary الناتج. كما أن نجاح static validation لا يثبت تشغيل dylib أو نجاح اختبار جهاز حقيقي.

## سياسة الأسماء القديمة

يُسمح بقاء الاسم القديم داخل التقارير التاريخية التي تشرح provenance، بشرط ألا يكون داخل Build input أو UI string أو asset أو product أو runtime identifier. أما أسماء الملفات والمجلدات القديمة الفعلية فقد أزيلت من المسارات النشطة بعد إثبات النقل الآمن، دون حذف الوثائق التاريخية لمجرد احتوائها على سياق سابق.

## مراجع داخلية

[1]: Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj/project.pbxproj
[2]: Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj/xcshareddata/xcschemes/TiktigerHost.xcscheme
[3]: .github/workflows/build-tiktiger-ios.yml
[4]: tools/validate_legacy_active_references.py
[5]: Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/src/TiktigerRuntime.c
[6]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerRuntimeCoordinator.swift

المصادر التنفيذية المشار إليها: [PBX project][1]، [Host scheme][2]، [CI workflow][3]، [Legacy Guard][4]، [C runtime][5]، و[Host RuntimeCoordinator][6].
