# Tiktiger 1.1 — Runtime Instrumentation Review

## نطاق المراجعة

تمت مراجعة lifecycle بعد طلب منع أي إعلان UI من داخل constructor. النتيجة هي أن `TiktigerRuntime.c` يعلن فقط `dylib_loaded` و`initializer_executed` و`core_started` و`feature_registry_ready`. لا يقوم constructor بتعيين `g_ui_registered` أو `g_ui_presented` ولا يستدعي دوال UI.

يحتفظ `TiktigerRuntimeCoordinator` بمقبض `dlopen` طوال عمر التطبيق ولا يستدعي `dlclose`. يسجل كل candidate path، ونتيجة `dlerror()` عند فشل التحميل، ونتيجة كل `dlsym()` في جدول `FOUND/FAILED`. كما أن `ui_registered` لا يُرسل إلا بعد أن يصبح probe view داخل `window` وله `superview`، و`ui_presented` لا يُرسل إلا بعد تحقق `window` و`superview` وnon-empty bounds.

## جدول الرموز المطلوب

يُنشئ Workflow بعد نجاح Build ملف `symbol_status.txt` ويضيفه إلى `verification.txt` وArtifacts. كل سطر يجب أن يكون واحدًا من القيمتين التاليتين؛ وجود أي `FAILED` يوقف Workflow:

| Symbol | Build result |
|---|---|
| `tt_product_name` | FOUND أو FAILED |
| `tt_version` | FOUND أو FAILED |
| `tt_runtime_initialize` | FOUND أو FAILED |
| `tt_runtime_dylib_loaded` | FOUND أو FAILED |
| `tt_runtime_initializer_executed` | FOUND أو FAILED |
| `tt_runtime_core_started` | FOUND أو FAILED |
| `tt_runtime_feature_registry_ready` | FOUND أو FAILED |
| `tt_runtime_mark_ui_registered` | FOUND أو FAILED |
| `tt_runtime_mark_ui_presented` | FOUND أو FAILED |
| `tt_runtime_ui_registered` | FOUND أو FAILED |
| `tt_runtime_ui_presented` | FOUND أو FAILED |
| `tt_runtime_diagnostics_json` | FOUND أو FAILED |
| `tt_feature_count` | FOUND أو FAILED |
| `tt_feature_key_at` | FOUND أو FAILED |
| `tt_set_feature_enabled` | FOUND أو FAILED |
| `tt_set_download_stage` | FOUND أو FAILED |

هذا الجدول يثبت تصدير الرموز من binary، لكنه لا يثبت أن Host استدعاها.

## Runtime milestones بالترتيب

| الترتيب | الحدث | من يملكه | شرط VERIFIED |
|---:|---|---|---|
| 1 | `dylib_loaded` | dyld/constructor + Host load report | وجود handle ونجاح path فعلي |
| 2 | `initializer_executed` | dylib constructor أو `tt_runtime_initialize` | probe C يساوي 1 مع timestamp |
| 3 | `core_started` | dylib bootstrap | probe C يساوي 1 مع registry bootstrap |
| 4 | `feature_registry_ready` | dylib bootstrap | count/keys موجودة |
| 5 | `ui_registered` | Host فقط | probe view داخل window وsuperview |
| 6 | `ui_presented` | Host فقط | probe view داخل hierarchy وبbounds غير فارغة بعد العرض |

يتم تسجيل timestamp بصيغة ISO-8601 في Host milestone table، وبـUnix seconds في C stderr log. Build-only Workflow لا يشغل التطبيق، ولذلك يكتب صراحة `Runtime milestones: NOT CAPTURED in build-only job` ولا يعلن `ui_presented`.

## فصل device وSimulator

مشروع dylib مضبوط على `SDKROOT=iphoneos` و`SUPPORTED_PLATFORMS=iphoneos` و`arm64`. Host PBX يستخدم `platformFilters = (iphoneos, )` لمرحلة Embed، لذلك لا يحاول Simulator تضمين device dylib. داخل Swift يوجد `#if targetEnvironment(simulator)`؛ في Simulator يسجل coordinator حالة `SKIPPED` مع سبب واضح ولا يستدعي `dlopen` على device binary.

Workflow يبني ثلاث مراحل منفصلة: dylib وHost على `iphoneos`، ثم Host على `iphonesimulator` بدون device dylib. السجلات هي `build.log` و`host_build.log` و`simulator_build.log`.

## الحدود الحالية

Static validation يثبت اتساق المصدر وPBX وWorkflow فقط. لا توجد في بيئة Linux أدوات Xcode ولا تشغيل تطبيق، لذلك أي جدول symbols أو milestones حقيقي سيظهر فقط داخل Artifacts بعد GitHub Actions وبعد تشغيل Host على Simulator أو جهاز. لا يُعتبر وجود الملف داخل IPA دليلًا على تنفيذ أي symbol أو milestone.
