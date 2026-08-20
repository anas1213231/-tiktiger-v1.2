# Tiktiger 1.1 — Known Issues and Remaining TODOs

هذا المستند يصف ما بقي بعد Safe Rename وLegacy Cleanup. لا توجد ادعاءات بأن الميزات أو binary أو Runtime تم اختبارها على iOS من البيئة الحالية.

## Build and signing

| Issue | Status | Impact | Required action |
|---|---|---|---|
| لا يوجد macOS/Xcode/iOS SDK في بيئة العمل الحالية | OPEN | لا يمكن إثبات `BUILD SUCCEEDED` أو فحص Mach-O محليًا | تشغيل `.github/workflows/build-tiktiger-ios.yml` على macOS؛ لا تُعلن XCODE VERIFIED قبل نجاحه |
| لا يوجد `Tiktiger.dylib` binary committed | INTENTIONAL | Host source build يحتاج binary حقيقيًا داخل `TigerHost/Runtime` عند دمج التطبيق | Workflow يبني binary ثم ينسخه إلى Host؛ لا تستخدم placeholder |
| Signing وTeam وProvisioning | PROVIDER / APP OWNER REQUIRED | Release على جهاز حقيقي يحتاج حساب Apple وentitlements صحيحة | ضبط `DEVELOPMENT_TEAM` وBundle ID والتوقيع في بيئة المالك المصرح |
| Real-device test | NOT RUN | Photos وFace ID وAVFoundation وdynamic loading غير مثبتة على جهاز | تشغيل Host على iPhone مصرح وتسجيل Console logs وDiagnostics |

## Runtime and integration

| Issue | Status | Impact | Required action |
|---|---|---|---|
| Runtime symbols لم تُفحص داخل binary حقيقي في هذه الجلسة | NOT VERIFIED | `FOUND` في source لا يساوي `nm -gU FOUND` | بعد CI، راجع `symbol_status.txt` و`verification.txt` |
| Host launch logs غير متوفرة | NOT CAPTURED | حالات DYLIB LOADED وINITIALIZER وCORE وUI لا يمكن إعلانها VERIFIED | شغّل التطبيق واحفظ Console output وMilestone timestamps |
| Host ↔ dylib Adapter | PARTIAL | `Integration/TiktigerHostAdapter.m` موجود ومتوافق مع contract لكنه ليس في Compile Sources للـHost الحالي | إما ربطه صراحة عند اعتماد bridge Objective-C، أو إبقاء RuntimeCoordinator هو المسار المعتمد وتوثيق القرار |
| App-level external hooks | NOT IMPLEMENTED | لا توجد hooks لتطبيق طرف ثالث أو لتجاوز توقيع/صلاحيات | يحتاج Integration/API مصرحًا ومشروع Host يملكه المستخدم؛ ليس جزءًا من هذه الحزمة |
| Simulator | EXPECTED SKIP | device dylib لا تُحمّل في Simulator | استخدم Simulator لاختبار UI فقط؛ استخدم device build/runtime للـdylib |

## Features and providers

| Issue | Status | Impact | Required action |
|---|---|---|---|
| Media resolver من رابط منشور أو صفحة تطبيق | PROVIDER REQUIRED | Direct HTTPS download يعمل فقط عندما يقدّم المستخدم direct media URL صالحًا | توفير endpoint/API مصرح وتطبيق `TiktigerMediaProvider` ثم اختبار MIME/status/error paths |
| Profile/Stories/Chats/Videos/Privacy external behaviors | PARTIAL أو NOT IMPLEMENTED حسب feature | UI والregistry لا يثبتان integration داخل مضيف خارجي | إضافة provider أو host-owned APIs مصرح بها، ثم تحديث `FEATURE_VERIFICATION.md` فقط بعد اختبار |
| Full localization | PARTIAL | اختيار اللغة يحفظ preference، لكن النصوص ليست localized بالكامل بعد launch | تنفيذ localization pass لاحقًا؛ ليس ضمن Safe Rename الحالية |
| Liquid Glass/OLED actual effects | PARTIAL | preferences وUI controls موجودة، لكن تأثيرها خارج Host preview غير مثبت | اختبار iOS version/device وتوصيل التأثيرات الفعلية قبل إعلانها VERIFIED |
| Photo Library and M4A | DEVICE TEST REQUIRED | المسار البرمجي موجود لكن صلاحيات النظام وAVAsset behavior غير مختبرة | اختبار Simulator/device مع ملفات وسائط مصرح بها |

## Legacy and documentation

لا توجد Legacy active references في PBX أو Schemes أو Workflow أو Compile Sources أو Resources أو Embed phases. بقيت بعض التقارير القديمة في مستودع العمل كسجل تاريخي فقط، ولم تُضمّن في قائمة ZIP النظيفة المختارة. لم تُحذف لمجرد الاسم، ولا تدخل في Build inputs.

## Verification policy

الحالة `STATIC VALIDATION: PASS` تعني سلامة source/PBX/Workflow checks فقط. لا تعني Xcode build أو signing أو Runtime launch. الحالة النهائية الصادقة ستبقى `XCODE BUILD NOT VERIFIED` إلى أن ينجح macOS Workflow فعليًا، وتبقى `Real-device test: NOT RUN` حتى يظهر log من iPhone حقيقي.
