# تقرير إعادة تصميم Tiktiger v2.0

## القرار التصميمي

تمت إزالة شكل النسخة القديمة بالكامل من المصدر. لم تعد هناك أقسام HOME أو DOWNLOADS أو MEDIA أو PROFILE أو CONFIRMATIONS أو SPEED & DEVELOPER. الواجهة الجديدة تعرض Privacy Lab فقط، مع أربع بطاقات واضحة ومفاتيح مستقلة.

## ما تم حذفه

حُذفت من نموذج المنتج وظائف التنزيل والوسائط والتأكيدات والسرعة والـ TapBot والخيارات العامة القديمة. كما أزيلت صور Base64 القديمة من `TiktigerResources.h`؛ الموارد الآن تُحمّل من bundle فقط، مع استخدام الصور الثلاث المعتمدة.

## ما تم الإبقاء عليه

بقيت ملفات Theos الأساسية، وملف Makefile، وملف plist، و`substrate.h`، وموارد الهوية، وGitHub Actions. بقيت الميزات الأربع المطلوبة فقط، مع guards مستقلة وحفظ مستقل.

## الملفات الجديدة في التصميم

`TiktigerPrefs.m` يحتوي تعريفات الميزات الأربع وحفظها. `TiktigerWindow.m` يحتوي واجهة Privacy Lab والـ launcher الجديد. `TiktigerHooks.m` يحتوي مجموعات hooks الأربع فقط. `TiktigerResources.h` يحتوي تحميلًا bundle-only للصور الجديدة.

## التحقق

يجب أن ينجح `tools/verify_privacy_merge.py` بدون أخطاء، ويجب أن يرفض workflow أي dSYM ويستخرج المكتبة التنفيذية من `.deb`. نجاح البناء لا يعادل اختبار Runtime؛ يجب تثبيت Artifact على Target مصرح ثم فحص كل مفتاح منفردًا.
