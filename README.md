# Tiktiger v1.2

Tiktiger هو مشروع Theos لتطبيق TikTok، من إعداد **@ucorc (Telegram)**. يحافظ هذا الإصدار على بنية المشروع السابقة ذات الملفات الفعلية التي يبنيها `Makefile`، مع إضافة الميزات الأربع الجديدة وموارد الهوية المعتمدة.

| الملف | نطاق التنفيذ |
|---|---|
| `TiktigerHooks.m` | Hooks الحالية، الميزات الأربع الجديدة، فحص class/selector، وتسجيل `MSHookMessageEx` بشكل محمي |
| `TiktigerPrefs.m` | التفضيلات، مفاتيح Settings، استخراج روابط الوسائط، التنزيل، والحفظ |
| `TiktigerWindow.m` | النافذة العائمة، Settings، التعريب، الشعار، سهم التحميل، وغلاف المطور |
| `TiktigerResources.h` | الصور المضمّنة القديمة مع أولوية موارد bundle الجديدة |
| `Tiktiger.plist` | قصر التعديل على bundle المضيف `com.zhiliaoapp.musically` |

## الميزات الأربع المضافة

| المفتاح | الميزة | مسار Hook |
|---|---|---|
| `anonymousProfiles` | Anonymous Profile Visits | `TTKProfileViewsVisitor` عند توفر selectors المناسبة |
| `unseenStories` | Keep Story Unseen | `TTKStoryManager markStoryReaded:` ومرشح `TTKStoryMarkReadService markAsRead:` |
| `unreadMessages` | Keep Messages Unseen | مسارات `AWEIMMessageReadComponent` الخاصة بمزامنة إيصال القراءة |
| `hideTyping` | Hide Typing | مرشحات `sendTyping` و`sendTypingStatus:` عند توفرها |

كل Hook يستخدم `TTInstallCheckedHook` الذي يفحص وجود class وselector قبل التسجيل. إذا لم يتوافق إصدار TikTok مع اسم selector، يتم تخطي Hook المحدد فقط وتسجيل ذلك في Console. يتم استخدام original IMP مستقل لكل class/selector في مسارات Hide Typing.

## الهوية والموارد

تم تحديث موارد الواجهة بالصور المعتمدة:

| الملف | الاستخدام |
|---|---|
| `assets/tiktiger-download.png` | سهم التحميل داخل الزر العائم وواجهات التحميل |
| `assets/tiktiger-main.png` | شعار Tiktiger الرئيسي |
| `assets/tiktiger-developer-cover.jpg` | غلاف المطور داخل رأس Settings مع طبقة تعتيم احترافية |

تُستخدم ملفات bundle الجديدة أولًا، مع الإبقاء على الصور المضمّنة القديمة كـ fallback في حال فشل تحميل resource أثناء الاختبار.

## البناء المحلي

على macOS مع Theos وiOS SDK مناسب:

```sh
export THEOS="$HOME/theos"
make clean
make package FINALPACKAGE=1
```

يدعم `Makefile` المعماريتين `arm64` و`arm64e`. لا يمكن بناء الـ dylib على بيئة Linux لا تحتوي Theos وiOS SDK.

## البناء عبر GitHub Actions

يقوم `.github/workflows/build.yml` بالبناء على `macos-14`، ويثبت Theos وiPhoneOS SDK، ثم ينفذ البناء ويتحقق من `Tiktiger.dylib` باستخدام `file` و`otool -L` وSHA-256. يرفع workflow الـ dylib وملف `.deb` وسجلات البناء كـ Artifact باسم `Tiktiger-dylib-<commit>`.

لشرح التحميل من الهاتف دون جهاز Apple، راجع `docs/BUILD_ARTIFACT_AR.md`.

## ملاحظة توافق لازمة

كلاسات TikTok المذكورة هنا كلاسات داخلية وليست API عامة. يجب توفير headers وتواقيع مطابقة لنسخة TikTok المثبتة؛ اختلاف اسم method أو توقيعه قد يجعل Hook بعينه غير فعال أو يمنع البناء. لذلك لا يتضمن المشروع headers مسرّبة أو SDK مملوكًا، ولا يمكن ضمان تشغيل كل Hook على جميع إصدارات TikTok من دون اختبار على نسخة محددة وجهاز اختبار معزول.

الملف `docs/TikTok_Tweaks_Static_Analysis_AR.md` مرفق كسياق للتحليل الثابت، وليس كإثبات تشغيل على جهاز.

## التحقق

شغّل:

```sh
python3 tools/verify_privacy_merge.py
git diff --check
```

نتيجة التحقق المصدرية الحالية: **0 أخطاء**. نجاح Runtime والبناء النهائي يتطلب تشغيل GitHub Actions واختبار الـ Artifact على Target مصرح.
