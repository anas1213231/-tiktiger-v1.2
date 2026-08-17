# ملخص التحقق — Tiktiger v2.0

تم تنفيذ التحقق المحلي بعد إعادة كتابة Settings وPreferences وHooks وResources وMakefile.

| الفحص | النتيجة |
|---|---:|
| `python3 tools/verify_privacy_merge.py` | `Errors: 0` |
| `git diff --check` | ناجح |
| مفاتيح الخصوصية | 4 فقط |
| الصور المعتمدة | 3 موارد bundle |
| معماريات البناء | `arm64`, `arm64e` |
| الحد الأدنى لـ iOS | `14.0` |
| مساحة Mach-O لإعادة التوقيع | مفعلة عبر header padding |

## نطاق v2.0

يحتوي المنتج على Anonymous Profile Visits وKeep Story Unseen وKeep Messages Unseen وHide Typing فقط. لكل ميزة مفتاح مستقل في namespace `Tiktiger.v2.`، وتستخدم الواجهة كتالوجًا واحدًا للبطاقات والمفاتيح، بينما تتحقق Hooks من class وselector قبل التثبيت.

## الموارد

يستخدم Makefile الموارد التالية فقط:

```text
assets/tiktiger-main.png
assets/tiktiger-download.png
assets/tiktiger-developer-cover.jpg
```

## فحص workflow

يجب أن يستخرج workflow `Tiktiger.dylib` من شجرة ملفات `.deb` بعد فكها، لا من مجلد `.theos`. كما يفحص `file` و`lipo -info` و`otool -l` وSHA-256، ويرفع `.deb` و`.dylib` وسجلات التحقق إلى Artifact واحد.

## ملاحظة اختبار Runtime

الفحص المحلي لا يغني عن البناء على macOS داخل GitHub Actions ولا عن اختبار Runtime على TikTok 46.3 داخل Target مصرح. يجب تبديل كل ميزة منفردة، إعادة تشغيل التطبيق، وفحص أن الحالة تُحفظ دون تغيير بقية المفاتيح.
