# Tiktiger 1.1

هذا المستودع هو مصدر Tiktiger 1.1 الجديد، ويحتوي على مشروع iOS المضيف ومشروع `Tiktiger.dylib` وWorkflow بناء حقيقي على macOS/Xcode.

## البنية

- `Tiktiger_1.1/TigerIOSStarter/`: مشروع iOS المضيف SwiftUI وTigerCore.
- `Tiktiger_1.1/Xcode_Dylib_Project/`: مشروع `TiktigerDylib.xcodeproj` ومصدر C وPublic API وScripts.
- `Tiktiger_1.1/Branding/`: الهوية والأصول الجديدة.
- `Tiktiger_1.1/Docs/` و`Tiktiger_1.1/Integration/`: وثائق البناء والتكامل والاختبار.
- `.github/workflows/build-tiktiger-ios.yml`: بناء Release فعلي لـ`iphoneos/arm64` والتحقق من Mach-O وMH_DYLIB والرموز وSHA-256.

## Real Xcode Build Verification

من GitHub افتح **Actions** ثم اختر **Build and Verify Tiktiger 1.1 iOS dylib** واضغط **Run workflow**. لا تعتبر المشروع XCODE VERIFIED إلا بعد ظهور `BUILD SUCCEEDED` ونجاح خطوة التحقق، ثم تحميل Artifact الذي يحتوي `Tiktiger.dylib` و`build.log` و`verification.txt`.

البناء يستخدم `CODE_SIGNING_ALLOWED=NO` و`CODE_SIGNING_REQUIRED=NO` لأن التحقق من dylib لا يساوي توقيع تطبيق مضيف. لا يوجد binary committed في المستودع؛ الناتج الحقيقي ينشأ داخل GitHub Actions فقط.

## ملاحظات التوقيع والتكامل

Bundle IDs وTeam وProvisioning وEntitlements النهائية للتطبيق المضيف تحتاج حساب Apple Developer مصرحًا. Provider الوسائط وربط Adapter وdylib بتطبيق مضيف مصرح هي خطوات تكامل منفصلة، وليست جزءًا من Real Xcode Build Verification.
