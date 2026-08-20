# Tiktiger 1.1 — Runtime Verification

هذا التقرير يثبت تصميم instrumentation ومسارات التحقق، لكنه لا يساوي تشغيلًا فعليًا. البيئة الحالية Linux ولا تحتوي Xcode أو iOS runtime، ولا يوجد binary committed يمكن تمريره إلى `nm` أو `otool`. لذلك كل حالة Runtime أدناه هي **NOT VERIFIED** ما لم يثبتها log من تشغيل Host على macOS/iOS. لا تُستخدم static source evidence لتغيير الحالة إلى VERIFIED.

## Runtime ownership model

يملك constructor في `TiktigerRuntime.c` milestones الخاصة بتحميل dylib وتهيئة initializer وبدء Core وجاهزية feature registry فقط. لا يكتب constructor إلى `g_ui_registered` أو `g_ui_presented`. يملك `TiktigerRuntimeCoordinator` في Host استدعاء `dlopen` واحتفاظ handle طوال عمر التطبيق، ثم يستدعي `dlsym` ويمرر UI milestones فقط بعد فحص `view.window` و`view.superview` وnon-empty bounds.

في Simulator، يستخدم Host شرط `targetEnvironment(simulator)` ويُسجّل أن تحميل device dylib تم تخطيه. كما يضع PBX Embed phase `platformFilters = (iphoneos, )` لمنع تضمين device binary في Simulator build. هذا التخطي متوقع وليس فشلًا في device runtime.

## Required symbol matrix

| Symbol | Static source status | Expected runtime role | Real binary status in current Linux session |
|---|---|---|---|
| `tt_product_name` | FOUND | Product identity | NOT VERIFIED — no macOS dylib inspected |
| `tt_version` | FOUND | Release version `1.1` | NOT VERIFIED — no macOS dylib inspected |
| `tt_runtime_initialize` | FOUND | Explicit Host initialization call | NOT VERIFIED |
| `tt_runtime_dylib_loaded` | FOUND | Load probe | NOT VERIFIED |
| `tt_runtime_initializer_executed` | FOUND | Constructor/bootstrap probe | NOT VERIFIED |
| `tt_runtime_core_started` | FOUND | Core bootstrap probe | NOT VERIFIED |
| `tt_runtime_feature_registry_ready` | FOUND | Registry count probe | NOT VERIFIED |
| `tt_runtime_mark_ui_registered` | FOUND | Host-owned UI registration marker | NOT VERIFIED |
| `tt_runtime_mark_ui_presented` | FOUND | Host-owned presentation marker | NOT VERIFIED |
| `tt_runtime_ui_registered` | FOUND | UI registration state probe | NOT VERIFIED |
| `tt_runtime_ui_presented` | FOUND | UI presentation state probe | NOT VERIFIED |
| `tt_runtime_diagnostics_json` | FOUND | Runtime milestone JSON | NOT VERIFIED |
| `tt_feature_count` | FOUND | Registry size | NOT VERIFIED |
| `tt_feature_key_at` | FOUND | Registry key enumeration | NOT VERIFIED |
| `tt_set_feature_enabled` | FOUND | Feature toggle forwarding | NOT VERIFIED |
| `tt_set_download_stage` | FOUND | Download pipeline stage forwarding | NOT VERIFIED |
| `tt_diagnostics_json` | FOUND | Feature/download diagnostics JSON | NOT VERIFIED |

`FOUND` في العمود الثاني يعني أن declaration والimplementation موجودان في مصدر Tiktiger الحالي ومربوطان في PBX dylib sources بحسب static validation. لا يعني ذلك أن symbol ظهر في `nm -gU` داخل binary. يجب أن يملأ GitHub Actions الجدول النهائي من `nm -gU BuildOutput/Tiktiger.dylib` بعد Build فعلي.

## Runtime milestones in required order

| Order | Milestone | Owner | Static implementation | Runtime status now | Timestamp evidence |
|---:|---|---|---|---|---|
| 1 | `DYLIB LOADED` | dylib constructor + Host `dlopen` | IMPLEMENTED | NOT VERIFIED | لا يوجد تشغيل حقيقي؛ Host يسجل ISO8601 وC يسجل `time(NULL)` |
| 2 | `INITIALIZER EXECUTED` | C bootstrap + Host `tt_runtime_initialize` | IMPLEMENTED | NOT VERIFIED | لا يوجد `build.log` أو Console log من iOS |
| 3 | `CORE STARTED` | C bootstrap | IMPLEMENTED | NOT VERIFIED | لا يوجد runtime timestamp حقيقي |
| 4 | `FEATURE REGISTRY READY` | C bootstrap بعد `tt_feature_count() > 0` | IMPLEMENTED | NOT VERIFIED | لا يوجد runtime timestamp حقيقي |
| 5 | `UI REGISTERED` | Host `markUIRegistered(from:)` فقط | IMPLEMENTED WITH GATE | NOT VERIFIED | لا يُسمح للconstructor بتعيينه؛ يتطلب `window != nil` و`superview != nil` |
| 6 | `UI PRESENTED` | Host `confirmPresented(from:)` فقط | IMPLEMENTED WITH GATE | NOT VERIFIED | يتطلب UI registered و`window` و`superview` وnon-empty bounds |

## Expected log format

عند تشغيل dylib الحقيقي، يجب أن تظهر رسائل C بصيغة مشابهة للآتي مع timestamps فعلية، مع عدم اعتبار هذا المثال log captured:

```text
[TiktigerRuntime] timestamp=<epoch-seconds> event=dylib_loaded product=Tiktiger version=1.1 sequence=<n>
[TiktigerRuntime] timestamp=<epoch-seconds> event=initializer_executed product=Tiktiger version=1.1 sequence=<n>
[TiktigerRuntime] timestamp=<epoch-seconds> event=core_started product=Tiktiger version=1.1 sequence=<n>
[TiktigerRuntime] timestamp=<epoch-seconds> event=feature_registry_ready product=Tiktiger version=1.1 sequence=<n>
[TiktigerRuntime] timestamp=<epoch-seconds> event=ui_registered product=Tiktiger version=1.1 sequence=<n>
[TiktigerRuntime] timestamp=<epoch-seconds> event=ui_presented product=Tiktiger version=1.1 sequence=<n>
```

الـHost يعرض أيضًا path الفعلي و`dlerror()` لكل candidate ونتيجة كل `dlsym` داخل Diagnostics. إذا فشل `dlopen` فالحالة الصادقة هي `DYLIB LOADED = FAILED`، ولا يُعد وجود الملف داخل IPA دليلًا على التنفيذ.

## Current conclusion

| Item | Result |
|---|---|
| Constructor sets UI milestones | NO — explicitly guarded |
| Host owns UI milestone updates | YES — source verified |
| Retained `dlopen` handle | YES — no `dlclose` path |
| `dlerror()` and `dlsym` reporting | YES — source verified |
| Simulator device dylib load | SKIPPED by guard |
| Real dylib symbol inspection | NOT VERIFIED in Linux |
| Real Host launch log | NOT CAPTURED |
| `XCODE VERIFIED` | NO |
| Real-device test | NOT RUN |

## مراجع داخلية

[1]: Tiktiger_1.1/TiktigerHost/TigerHost/TiktigerRuntimeCoordinator.swift
[2]: Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/src/TiktigerRuntime.c
[3]: Tiktiger_1.1/Xcode_Dylib_Project/TiktigerDylib/include/Tiktiger.h
[4]: .github/workflows/build-tiktiger-ios.yml

الأدلة: [Host coordinator][1]، [C instrumentation][2]، [public contract][3]، و[macOS workflow][4].
