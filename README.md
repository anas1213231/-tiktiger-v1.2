# Tiktiger v1.1

Tiktiger هو مشروع Theos لتطبيق TikTok، من إعداد **@ucorc (Telegram)**. تمت إعادة تقسيم التنفيذ إلى ملفات hooks مستقلة حتى لا تكون لوحة الإعدادات منفصلة عن مسارات التنفيذ.

| الملف | نطاق التنفيذ |
|---|---|
| `TiktigerFeed.xm` | الصفحة الرئيسية، زر البرق، تعطيل التحديث، الإعلانات، اسم المستخدم، الدولة، التعليقات، التقدم، التحميل، الحساسية، التكرار، البث |
| `TiktigerDownload.xm` | تنزيل الستوري، منع تعليمها كمقروءة، وتنفيذ زر التنزيل عبر `NSURLSession` |
| `TiktigerMessages.xm` | القراءة، مؤشر الكتابة، تكرار الرسائل، وحفظ الوسائط بالضغط المطول |
| `TiktigerProfile.xm` | الصورة الرمزية، السيرة، الشارات، حالة المتابعة، الإعجابات، تواريخ الرفع، والتصفح المجهول |
| `TiktigerConfirm.xm` | تأكيد الإعجاب، إعجاب التعليق، إلغاء الإعجاب، والمتابعة |
| `TiktigerMisc.xm` | التحذيرات، Safari، حدود النص، الرفع عالي الجودة، القفل، زر البث، وسرعة التشغيل |
| `TiktigerMedia.xm` | الصور، AVFoundation، جلسة الكاميرا، إخراج الإطارات، وجلسة الصوت |
| `TiktigerUI.m` و`TiktigerPrefs.m` | واجهة الإعدادات المقسمة، التوطين، التفضيلات، التنزيلات، التأكيدات، والموارد |

## البناء

على macOS مع Theos وiOS SDK مناسب، شغّل:

```sh
make package FINALPACKAGE=1
```

يدعم `Makefile` المعماريتين `arm64` و`arm64e`. يقوم `.github/workflows/build.yml` بالبناء على macOS، ثم يتحقق من `Tiktiger.dylib` باستخدام `file` و`otool -L` وSHA-256، ويرفع الـdylib والحزمة deb وسجلات البناء كـartifact باسم `Tiktiger-dylib-<commit>`.

## ميزات الخصوصية المضافة

تمت إضافة أربع ميزات مستقلة داخل مفاتيح التفضيلات الحالية، مع الحفاظ على التوافق مع Settings القديم:

| المفتاح | الميزة | مسار hook |
|---|---|---|
| `anonymousProfiles` | Anonymous Profile Visits | `TTKProfileViewsVisitor` عند توفر selectors المناسبة |
| `unseenStories` | Keep Story Unseen | `TTKStoryManager markStoryReaded:` ومرشح `TTKStoryMarkReadService markAsRead:` |
| `unreadMessages` | Keep Messages Unseen | مسارات `AWEIMMessageReadComponent` الخاصة بمزامنة إيصال القراءة |
| `hideTyping` | Hide Typing | مرشحات `sendTyping` و`sendTypingStatus:` عند توفرها |

كل Hook يستخدم `TTInstallCheckedHook` الذي يفحص وجود class وselector قبل تسجيله. إذا لم يتوافق إصدار TikTok مع اسم selector، يتم تخطي Hook المحدد فقط وتسجيل ذلك في Console.

## ملاحظة توافق لازمة

كلاسات TikTok المذكورة هنا كلاسات داخلية وليست API عامة. يجب توفير headers وتواقيع مطابقة لنسخة TikTok المثبتة؛ اختلاف اسم method أو توقيعه قد يجعل hook بعينه غير فعال أو يمنع البناء. لذلك لا يتضمن المشروع headers مسرّبة أو SDK مملوكاً، ولا يمكن ضمان تشغيل كل hook على جميع إصدارات TikTok من دون اختبار على نسخة محددة وجهاز اختبار معزول.

الملف `docs/TikTok_Tweaks_Static_Analysis_AR.md` مرفق كسياق للتحليل الثابت، وليس كإثبات تشغيل على جهاز.

> عدد الصفوف في الواجهة يطابق 51 بنداً عملياً، لأن قائمة المتطلبات المرفقة نفسها ترقّم البنود من 1 إلى 51 رغم وصفها بأنها 50 ميزة.
