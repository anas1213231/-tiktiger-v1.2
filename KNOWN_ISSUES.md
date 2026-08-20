# Tiktiger 1.1 — Known Issues and Remaining TODOs

هذا المستند يصف ما بقي بعد إكمال Host-only paths وSafe Rename وLegacy Cleanup ونجاح GitHub Xcode verification. لا توجد ادعاءات بأن Runtime الجهاز الحقيقي أو صلاحيات النظام قد اختُبرت قبل وصول تقارير iPhone.

## Build and signing

| Issue | Status | Impact | Required action |
|---|---|---|---|
| Xcode/macOS build | **VERIFIED** في GitHub Actions run `32389935401` | dylib وHost device وHost simulator وIPA packaging اجتازت BUILD SUCCEEDED | احتفظ بـ`verification.txt` و`build.log` وartifact كدليل. |
| Final Apple signing | **OWNER ACTION REQUIRED** | IPA الحالية Unsigned/Signable وليست موقعة من Apple | أعد توقيع IPA في eSign بشهادة وProvisioning مصرح بهما. |
| Bundle IDs | **FIXED** | هوية التطبيق يجب أن تطابق Provisioning | Host: `com.ucorc.Tiktiger`؛ Core: `com.ucorc.TiktigerCore`. |
| Real-device test | **NOT RUN** | Photos وFace ID وAVFoundation وdevice dynamic loading غير مثبتة على iPhone | ثبّت نسخة eSign على iPhone وصدّر تقارير Self-Diagnostics. |

## Runtime and integration

| Issue | Status | Impact | Required action |
|---|---|---|---|
| Device dylib runtime milestones | **NOT VERIFIED** | لا يمكن إعلان `DYLIB LOADED` أو `CORE STARTED` أو `UI PRESENTED` من Simulator | أرسل `device-runtime.json` و`device-console.log` و`DEVICE_RUNTIME_VERIFICATION.md`. |
| Host launch in Simulator | **VERIFIED** في آخر run | signing/install/launch/screenshot نجحت بعد إصلاح TigerCore install name | لا يُستخدم هذا لإثبات device dylib runtime. |
| TigerCore framework install name | **FIXED** | كان يبحث عن `/Library/Frameworks/TigerCore.framework/TigerCore` ويسبب dyld crash في Simulator | أصبح `@rpath/TigerCore.framework/TigerCore` مع Host runpath `@executable_path/Frameworks`. |
| Host ↔ dylib Adapter | **PARTIAL BY DESIGN** | `Integration/TiktigerHostAdapter.m` موجود ومتوافق، لكن RuntimeCoordinator هو المسار المربوط في Host target | لا تُضف bridge إضافية إلا عند حاجة Integration مصرح بها. |
| App-level external hooks | **NOT IMPLEMENTED** | لا توجد hooks لتطبيق طرف ثالث أو تجاوز توقيع/صلاحيات | يحتاج API/Host integration مصرحًا ومختلفًا عن هذه الحزمة. |
| Simulator device dylib loading | **EXPECTED SKIP** | device dylib لا تُحمّل في Simulator عمدًا | استخدم Simulator للـUI فقط؛ استخدم device eSign للـdylib runtime. |

## Features and providers

| Feature | Status | Remaining requirement |
|---|---|---|
| Master Switch | **IMPLEMENTED NOT TESTED** | enable/disable/terminate/relaunch ومراجعة dependent rows وaudit events على الجهاز. |
| Appearance | **IMPLEMENTED NOT TESTED** | Light/Dark/System، جميع الشاشات وSheets، ثم restart على الجهاز. |
| Translation | **IMPLEMENTED NOT TESTED** | English/Arabic، LTR/RTL، runtime switch، restart، ومراجعة عدم ظهور keys. |
| Diagnostics | **IMPLEMENTED NOT TESTED** | Export فعلي من iPhone ومراجعة الملفات الثلاثة. |
| Direct HTTPS Download | **IMPLEMENTED NOT TESTED** | اختبار رابط HTTPS مباشر مصرح مع HTTP/MIME/progress/history/cancel/retry. |
| Published/Page URL Download | **PROVIDER REQUIRED** | يلزم Provider/API مصرح لتحويل Page URL إلى direct media URL؛ لا يوجد fake provider. |
| Cancel / Retry | **IMPLEMENTED NOT TESTED** | اختبار cancellation وfailure→retry على network وaudio path. |
| Photos | **DEVICE TEST REQUIRED** | authorized/denied/restricted/save success/save failure. |
| M4A | **DEVICE TEST REQUIRED** | valid/no-audio/export failure/cancel/output/playability. |
| Share | **IMPLEMENTED NOT TESTED** | valid/missing file، completion، cancel، cleanup، وDiagnostics multi-file share. |
| Face ID | **DEVICE TEST REQUIRED** | success/failure/user cancel/unavailable/not enrolled. |
| Chats Lock | **PARTIAL** | لا يوجد Chats protected screen أو unlock flow حقيقي في Host الحالي؛ لا fake implementation. |
| Favorites Lock | **PARTIAL** | لا يوجد Favorites protected screen أو unlock flow حقيقي في Host الحالي؛ لا fake implementation. |
| Profile/Stories/Videos/Privacy/Miscellaneous rows | **PARTIAL / NOT IMPLEMENTED / PROVIDER REQUIRED** | الحالات التفصيلية ومسارات النقص موثقة في `FEATURE_END_TO_END_MAP.md`. |

## Legacy and source boundary

لا توجد Legacy active references في PBX أو Schemes أو Workflow أو Compile Sources أو Resources أو Embed phases. لا تُستخدم `FeatureKit` أو `TigerIOSStarter` أو `VibeTok` في Build inputs. يعتمد المشروع على Source of Truth الحالي فقط.

## Integrity and security

لم تتغير `Tiktiger.dylib` المعتمدة. SHA-256 المرجعية هي:

```text
c74d63937efdb58421382910e0de0c5cd23dd8ee046c986f8f4698e678a31c80
```

Install name الخاص بـdylib هو `@rpath/Tiktiger.dylib`. لا يجب أن تحتوي تقارير Self-Diagnostics على Tokens أو Cookies أو Credentials أو Private Keys أو بيانات شخصية؛ استخدم sanitizer ولا تضع أسرارًا في test URLs.

## Verification policy

`STATIC VALIDATION: PASS` يعني سلامة source/PBX/Workflow checks فقط. `XCODE VERIFIED: YES` في هذه النسخة يستند إلى run `32389935401` الذي سجل `BUILD SUCCEEDED` وartifact checks. `TIKTIGER RUNTIME VERIFIED` يبقى **NO** حتى يصل تقرير iPhone حقيقي يثبت التسلسل:

```text
dylib_loaded
initializer_executed
core_started
feature_registry_ready
ui_registered
ui_presented
```
