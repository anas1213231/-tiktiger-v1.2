# تشغيل Build Verification على GitHub Actions

1. فكّ `Tiktiger_GitHub_Actions_READY.zip`، ثم انسخ محتوياته إلى جذر مستودع GitHub مع الحفاظ على المسارات:
   `.github/workflows/build-tiktiger-ios.yml` و`Tiktiger_1.1/Xcode_Dylib_Project/`.

2. ارفع التغييرات إلى فرع `main`:

```bash
git add .github/workflows/build-tiktiger-ios.yml Tiktiger_1.1 tools/validate_tiktiger_workflow.py
git commit -m "Add real macOS Xcode build verification for Tiktiger 1.1"
git push origin main
```

3. افتح تبويب **Actions** في GitHub، اختر **Build and Verify Tiktiger 1.1 iOS dylib**، ثم اضغط **Run workflow** واختر الفرع واضغط **Run workflow** مرة أخرى.

4. انتظر حتى تظهر نتيجة ناجحة تحتوي على `BUILD SUCCEEDED` ونجاح `file/lipo/otool/nm/shasum`. افتح الـRun ثم **Artifacts** وحمّل:
   `Tiktiger-1.1-ios-arm64-<commit-sha>`.

5. بعد فك Artifact ستجد `Tiktiger.dylib` و`build.log` و`verification.txt`. لا تعتبر المشروع XCODE VERIFIED إلا إذا نجحت المهمة واحتوى `verification.txt` على `BUILD STATUS: BUILD SUCCEEDED and binary verification passed`.

> لا يحتاج هذا Workflow إلى Apple signing لأن البناء يستخدم `CODE_SIGNING_ALLOWED=NO` و`CODE_SIGNING_REQUIRED=NO`. التوقيع النهائي للتطبيق المضيف يظل خطوة منفصلة.
