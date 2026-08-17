# استخراج Tiktiger.dylib من GitHub Actions

بعد رفع التعديلات إلى الفرع `main`، افتح تبويب **Actions** في المستودع، ثم اختر workflow باسم **Build Tiktiger dylib**. افتح آخر تشغيل ناجح، وانزل إلى قسم **Artifacts**. حمّل الملف الذي يبدأ باسم `Tiktiger-dylib-`.

بعد فك الضغط ستجد عادةً:

```text
Tiktiger.dylib
Tiktiger-*.deb
file.txt
otool-L.txt
sha256.txt
make-clean.log
make-package.log
```

إذا ظهر التشغيل باللون الأحمر، افتح الخطوة التي فشلت واقرأ `make-package.log` أو سجل الخطوة نفسها. أكثر الأسباب شيوعًا هي تغيّر iOS SDK أو عدم توافق class/selector مع إصدار TikTok المستهدف.

لا تحتاج إلى جهاز Apple لتشغيل GitHub Actions؛ GitHub يستخدم runner يعمل على macOS. لا ترفع أي ملف dylib تم الحصول عليه من مصدر غير موثوق، وراجع `sha256.txt` وسجل البناء قبل استخدام الـ artifact على Target مصرح.
