# Legacy Dependency Audit + Safe Rename Report

أُجري التدقيق على شجرة Tiktiger الحالية مع فصل Build inputs عن الوثائق التاريخية. القاعدة المستخدمة هي أن الاسم القديم يُعد **Active** فقط إذا دخل في PBX project أو Scheme أو Workflow أو Compile Sources أو Resources أو Embed phase أو Runtime path. أما ظهوره في تقرير تاريخي فهو Documentation only ولا يُعد تلوثًا في البناء.

| Legacy Name | Location | Active? | Action | New Name | Verification |
|---|---|---:|---|---|---|
| `TigerIOSStarter` | مجلد Host ومشروع `TigerIOSStarter.xcodeproj` قبل النقل | نعم | نُقل المجلد والمشروع مع الحفاظ على PBX UUIDs | `TiktigerHost/` و`TiktigerHost.xcodeproj` | المسار القديم غير موجود؛ Legacy Guard PASS |
| `TigerIOSStarter` | PBX project comment وconfiguration-list comments | نعم | تحديث comment strings فقط | `TiktigerHost` | PBX يعلن `TiktigerHost`؛ UUID duplicate = 0 |
| `TigerIOSStarter` | `TigerHost.xcscheme` و`TigerCore.xcscheme` قبل النقل | نعم | نُقل Scheme الرئيسي وأُصلحت `ReferencedContainer` | `TiktigerHost.xcscheme` و`container:TiktigerHost.xcodeproj` | Scheme XML صالح؛ Blueprint IDs محفوظة |
| `TigerIOSStarter` | `.github/workflows/build-tiktiger-ios.yml` | نعم | تحديث Host directory وproject path | `Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj` | Workflow validator PASS |
| `TigerIOSStarter` | `tools/validate_merged_tiktiger.py` و`tools/validate_tiktiger_workflow.py` | نعم | تثبيت validators على الشجرة الجديدة | `TiktigerHost` | كلا validatorين PASS |
| `TigerIOSStarter` | `README.md` و`TiktigerHost/README_AR.md` | لا، وثائق مسار | تحديث تعليمات الاستخدام إلى المشروع وScheme الجديدين | `TiktigerHost.xcodeproj` و`TiktigerHost` | لا يوجد مرجع نشط؛ الوثائق تشير للمسار الحالي |
| `TigerIOSStarter` | `Tiktiger_1.1/FINAL_CHECKPOINT_AR.md` و`RUNTIME_FIX_REPORT_AR.md` | لا، Documentation only | الاحتفاظ بها كسجل تاريخي؛ لم تدخل الحزمة النظيفة المختارة | لا ينطبق | مستبعدة من Active Guard ومن قائمة ZIP النظيفة |
| `FeatureKit` | `TigerHost/Runtime/README_AR.md` كتحذير قديم عن اسم binary | لا، وثيقة Runtime | استبدال الاسم القديم بوصف عام لـbinary غير موثوق | لا يوجد legacy product name | grep active لا يعثر عليه؛ الملف يشرح Tiktiger.dylib فقط |
| `FeatureKit` | ملفات Build/Compile/Resources/Embed | لا | لم يُعثر على ملف أو PBX reference فعلي | لا ينطبق | `LEGACY ACTIVE REFERENCES: 0` |
| `VibeTok` | `FINAL_ENGINEERING_REPORT_AR.md` كسياق تاريخي | لا، Documentation only | الاحتفاظ بالسياق التاريخي خارج Build inputs | لا ينطبق | لا يظهر في UI strings أو assets أو product/runtime identifiers |
| `VibeTok` | Swift/C/PBX/Schemes/Workflow/Assets | لا | لم يُعثر على مرجع نشط | لا ينطبق | Legacy Guard PASS؛ `OLD UI IN BUILD: NO` و`OLD ASSETS IN BUILD: NO` |
| `TigerHostApp.swift` و`TigerHost.app` | PBX وProduct وScheme، كاعتماد تابع لإعادة تسمية Host | نعم، تابع | إعادة تسمية ملف entry point والمنتج والـtarget مع حفظ UUIDs | `TiktigerHostApp.swift` و`TiktigerHost.app` ثم `TiktigerHost.app` product | Compile Sources وScheme وPBX paths متطابقة |

## نتيجة الفحص النشط

فشل الحارس عمدًا عند اكتشاف مشكلات داخل منطق الحارس نفسه، ثم صُحح وأُعيد تشغيله حتى مرّ الفحص الفعلي. النتيجة النهائية هي:

| Check | Result |
|---|---|
| Active Host project | `TiktigerHost.xcodeproj` |
| Active Host target | `TiktigerHost` |
| Active Host scheme | `TiktigerHost.xcscheme` |
| Active dylib project | `TiktigerDylib.xcodeproj` |
| Legacy active references | `0` |
| Broken PBX references | `0` |
| Duplicate UUIDs | `0` |
| Old UI in Build | `NO` |
| Old assets in Build | `NO` |
| Legacy Guard | `PASS` |

لم تُحذف ملفات المصدر أو الميزات الموجودة بسبب الاسم فقط. لم يُعثر على FeatureKit أو VibeTok binary أو source file ميت ذي اسم Legacy يحتاج حذفًا؛ أما الوثائق التاريخية فتم تمييزها بوضوح ولم تُعامل كـBuild contamination.

## مراجع داخلية

[1]: tools/validate_legacy_active_references.py
[2]: tools/validate_merged_tiktiger.py
[3]: tools/validate_tiktiger_workflow.py
[4]: Tiktiger_1.1/TiktigerHost/TiktigerHost.xcodeproj/project.pbxproj
[5]: .github/workflows/build-tiktiger-ios.yml

التحقق مبني على [Legacy Guard][1] و[merged-project validator][2] و[Workflow validator][3]، مع مراجعة [PBX project][4] و[CI workflow][5].
