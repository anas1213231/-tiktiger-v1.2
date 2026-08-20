# Tiktiger 1.1 Runtime Fix Checkpoint

تم إصلاح مسار التشغيل في المصدر:

- Host يملك `TiktigerRuntimeCoordinator.swift`.
- Host يضمّن `TigerHost/Runtime/Tiktiger.dylib` عبر PBX Embed phase وCodeSignOnCopy على iphoneos فقط.
- dylib تحتوي constructor وruntime markers وJSON diagnostics؛ constructor لا يعلن UI.
- Host يحتفظ بـdlopen handle، ويسجل path/dlerror/dlsym وtimestamps، ولا يستدعي dlclose.
- `ui_registered` و`ui_presented` لا يحدثان إلا بعد view hierarchy confirmation.
- Simulator لا يحاول تحميل device dylib، وWorkflow يبني Host simulator منفصلًا.
- Feature registry keys وDownloadStage تمر إلى Public API عند توفر binary الحقيقي.
- Workflow يبني dylib ثم يبني TigerHost iphoneos، ثم TigerHost iphonesimulator بدون device dylib، ويتحقق من وجود dylib داخل `Frameworks/TigerHost.app`.
- Workflow ينشئ `symbol_status.txt` بجدول FOUND/FAILED؛ Runtime milestones لا تُعلن من Build-only job.
- لا يوجد binary وهمي أو binary committed داخل المصدر.
- TiktigerFeatures.c لم يتغير في هذا الإصلاح.

الحالة الحالية: **STATIC FIX READY / XCODE BUILD NOT VERIFIED / DEVICE RUNTIME NOT VERIFIED**.

شرط الإكمال: تشغيل Workflow على macOS، نجاح `BUILD SUCCEEDED` لكل من dylib وTigerHost، تشغيل التطبيق على Simulator أو iPhone، ثم التقاط markers:
`dylib_loaded`, `initializer_executed`, `core_started`, `feature_registry_ready`, `ui_registered`, `ui_presented`.
