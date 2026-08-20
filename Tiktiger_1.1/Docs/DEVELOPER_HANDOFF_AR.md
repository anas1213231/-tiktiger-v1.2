# Tiktiger — Developer Handoff

## الهدف

هذه الحزمة هي نقطة تسليم واضحة للمطور أو لمساعد برمجي بالذكاء الاصطناعي.
المطلوب هو تحويل المصدر الحالي إلى Build فعلي على macOS/Xcode، والتحقق من أن الناتج النهائي:

`Tiktiger.dylib`

هو Mach-O حقيقي لـ iOS arm64.

> مهم: المشروع الحالي لا يقوم بحقن مكتبة داخل تطبيقات طرف ثالث ولا يتجاوز توقيع Apple.
> أي دمج يجب أن يكون داخل تطبيق يملكه صاحب المشروع أو بيئة اختبار مصرح بها.

---

## الموجود داخل الحزمة

### 1. Xcode_Dylib_Project
مشروع Xcode جاهز يحتوي على:

- Target: `TiktigerDylib`
- SDK: `iphoneos`
- Architecture: `arm64`
- Mach-O Type: `mh_dylib`
- Product: `Tiktiger.dylib`
- Install Name: `@rpath/Tiktiger.dylib`
- Build script
- Verify script
- Automatic export to `BuildOutput/Tiktiger.dylib`

### 2. Docs
مواصفات المشروع، خطة الاختبار، وتعليمات التسليم.

### 3. AI
Prompt جاهز لأي AI coding agent حتى يفهم المشروع ويبدأ العمل بدون تخمين.

### 4. Integration
عقود API وملاحظات الربط الآمن مع التطبيق المضيف.

---

# المطلوب من المطور

## المرحلة 1 — فتح وفحص المشروع

1. فك الضغط.
2. افتح:
   `Xcode_Dylib_Project/TiktigerDylib.xcodeproj`
3. تأكد أن Xcode لا يقوم بتحويل SDK إلى macOS.
4. تأكد أن Target هو `TiktigerDylib`.
5. تأكد أن Product الناتج هو `Tiktiger.dylib`.

## المرحلة 2 — Build فعلي

يمكن البناء من Terminal:

```bash
cd Xcode_Dylib_Project
./BUILD_TIKTIGER.command
```

أو من Xcode:

- Scheme: `TiktigerDylib`
- Destination: Any iOS Device (arm64)
- Configuration: Release
- Product → Build

## المرحلة 3 — التحقق من الناتج

يجب تنفيذ:

```bash
file BuildOutput/Tiktiger.dylib
lipo -info BuildOutput/Tiktiger.dylib
otool -hv BuildOutput/Tiktiger.dylib
otool -L BuildOutput/Tiktiger.dylib
```

المتوقع:

- Mach-O 64-bit dynamically linked shared library
- arm64
- iOS target
- Install name = `@rpath/Tiktiger.dylib`

## المرحلة 4 — اختبار API الحالية

الـ Public API موجود هنا:

`TiktigerDylib/include/Tiktiger.h`

والتنفيذ هنا:

- `TiktigerDylib/src/Tiktiger.c`
- `TiktigerDylib/src/TiktigerFeatures.c`

النواة الحالية تقدم API قابلة للاختبار وليست مجرد ملف فارغ:

- هوية المنتج والإصدار 1.1.
- enable/disable وcounter وuppercase وchecksum.
- feature flags لمفاتيح التنزيل والرسائل والقفل والملف الشخصي والمظهر.
- تحقق HTTPS دون تنفيذ شبكة.
- تنظيف أسماء الملفات قبل التخزين.
- مراحل تنزيل Idle/Validating/Downloading/ExtractingAudio/Saving/Completed/Failed/Cancelled.
- diagnostics JSON صغير لا يحتوي أسرارًا أو بيانات مستخدم.

تظل URLSession وPhotos وAVFoundation وLocalAuthentication وواجهة SwiftUI داخل خدمات وAdapter التطبيق المضيف، لا داخل نواة C. يوفّر المضيف الآن `TigerHost/Services/TiktigerMediaDownloadService.swift` لمسار HTTPS المباشر مع cancellation وretry/history، بينما يبقى تحويل رابط منشور إلى رابط وسائط خلف `TiktigerMediaProvider` وحالته `PROVIDER REQUIRED` حتى توفير API مصرح. راجع `Docs/TIKTIGER_FEATURE_MAP_AR.md` لمصفوفة الربط والمسارات الحقيقية.

---

# متطلبات Tiktiger 1.1 عند دمجه مع تطبيق مضيف

هذه المتطلبات تخص التطبيق المضيف وليست كلها داخل dylib الحالية:

- هوية وشعار Tiktiger
- AppIcon
- واجهة رئيسية
- Appearance
- Translation
- Diagnostics
- تنزيل مباشر عبر Provider/API مصرح
- حفظ Photos مع الصلاحيات النظامية
- استخراج صوت M4A
- مشاركة الملفات
- قفل Chats / Favorites عبر LocalAuthentication
- قسم المطور `@ucorc`
- رابط Telegram
- معالجة أخطاء موحدة

## قاعدة معمارية

لا تضع كل الوظائف في ملف واحد.

استخدم تقسيمًا مثل:

```text
Tiktiger/
├─ Core/
│  ├─ TTCore
│  ├─ TTLogger
│  └─ TTDiagnostics
├─ Services/
│  ├─ TTDownloadService
│  ├─ TTAudioService
│  ├─ TTPhotosService
│  ├─ TTAuthService
│  ├─ TTTranslationService
│  └─ TTAppearanceService
├─ Models/
├─ UI/
└─ Integration/
```

الفصل بين Services وUI وIntegration إلزامي حتى يبقى المشروع قابلًا للصيانة.

---

# Definition of Done

لا تعتبر المهمة مكتملة إلا بعد:

- [ ] نجاح Clean Build في Release.
- [ ] خروج `Tiktiger.dylib` حقيقي.
- [ ] التحقق من Mach-O وarm64.
- [ ] لا توجد أخطاء Compile أو Link.
- [ ] معالجة جميع Warnings المهمة.
- [ ] API عامة واضحة.
- [ ] عدم وجود secrets داخل المصدر.
- [ ] Diagnostics تعمل.
- [ ] جميع حالات الخطأ تعرض رسالة مفهومة.
- [ ] اختبار التطبيق المضيف على iPhone حقيقي إذا كان الدمج مطلوبًا.
- [ ] توثيق خطوات إعادة البناء.

---

# ما يجب تسليمه لصاحب المشروع

1. `Tiktiger.dylib` إذا نجح Build حقيقي فقط.
2. نسخة Source النهائية.
3. `BuildLogs/latest-build.log` و`BuildLogs/verification.txt` وSHA-256 عند توفر macOS/Xcode.
4. Screenshot من Xcode Build Succeeded
5. نتيجة:
   - `file`
   - `lipo -info`
   - `otool -L`
6. قائمة ما تم وما لم يتم
7. أي متطلبات Signing أو Provisioning لازمة للتطبيق المضيف
