# بناء Artifact — Tiktiger v2.0

يبني GitHub Actions الحزمة على macOS مع Theos وiPhoneOS SDK، ثم ينفذ `make package FINALPACKAGE=1` ويجمع ملف `.deb` الناتج. بعد ذلك يفك الحزمة في مجلد مؤقت ويستخرج الملف التنفيذي من `usr/lib/TweakInject/Tiktiger.dylib` أو `Library/MobileSubstrate/DynamicLibraries/Tiktiger.dylib`، بدل استخدام ملفات `.theos/obj` أو ملفات dSYM المرافقة.

## مخرجات التشغيل

| الملف | الغرض |
|---|---|
| `Tiktiger-v2.0.deb` | حزمة التثبيت المبنية |
| `Tiktiger.dylib` | الملف التنفيذي المستخرج من داخل الحزمة |
| `SHA256SUMS.txt` | بصمات SHA-256 للمخرجات |
| `verification/file.txt` | إثبات أن الملف Mach-O dylib تنفيذي وليس dSYM |

## شروط النجاح

يجب أن ينجح فحص `file` باعتبار المكتبة **dynamically linked shared library**، وأن يعرض `lipo -info` معماريتي `arm64` و`arm64e`، وأن يحتوي `otool -l` على مسار التوقيع المتوقع ومساحة header كافية لإعادة التوقيع والحقن. يرفض workflow أي ملف ينتهي باسم `dSYM` أو يحتوي على companion لا يمثل المكتبة التنفيذية.

## حدود التحقق

نجاح workflow يثبت أن المصدر قابل للبناء وأن Artifact المستخرج هو الملف التنفيذي الصحيح. لا يثبت وحده وجود كل selector في نسخة TikTok المستهدفة؛ لذلك تُجرى اختبارات Runtime منفصلة على جهاز مصرح وبنسخة TikTok 46.3، مع اختبار كل مفتاح على حدة.
