# خريطة ميزات Tiktiger 1.1 ومسارات الربط

## المبدأ

ملف `Tiktiger.dylib` هو نواة قابلة لإعادة الاستخدام. أما الواجهة SwiftUI وخدمات Photos وAVFoundation وLocalAuthentication وربط التطبيق المضيف فتوجد في المشروع المضيف. لا توجد فائدة من وضع SwiftUI داخل dylib C صغيرة؛ النتيجة الصحيحة هي Adapter يستدعي Public API ويعيد الحالات إلى UI.

## مصفوفة الميزات

| القسم | الزر أو الخيار | مسار التنفيذ الحقيقي | مكان التنفيذ | حالة المصدر الحالي |
|---|---|---|---|---|
| Core | Master Switch | قراءة وكتابة حالة النواة ثم تفعيل الوحدات المسموحة | `Tiktiger.c` + Adapter | جاهز كنواة |
| Diagnostics | فحص الوحدة | `tt_diagnostics_json` وقراءة stage وfeature flags | dylib + UI | جاهز كنواة، يحتاج عرض المضيف |
| Downloads | Video / Image | تحقق HTTPS، URLSession، ملف مؤقت، MIME/extension، Photos | Adapter المضيف | موجود في Host starter |
| Downloads | Audio M4A | تنزيل مؤقت، AVAssetExportSession، حفظ Documents، Share Sheet | Adapter المضيف | موجود في Host starter |
| Downloads | Provider | تحويل رابط المنشور إلى رابط وسائط | API/Adapter مصرح | غير مربوط حتى توفير endpoint |
| Stories | Download Stories | الحصول على رابط مصرح، ثم نفس Download Coordinator | Adapter المضيف | تصميم ومسار محدد |
| Chats | Lock Chats | LocalAuthentication ثم فتح واجهة الرسائل | Adapter المضيف | موجود محليًا في Host starter |
| Privacy | Lock Favorites | LocalAuthentication ثم السماح بالوصول | Adapter المضيف | موجود محليًا في Host starter |
| Profile | Private Profile | gate قبل مسار الزيارة في المضيف | Host integration | يحتاج selector/API المضيف |
| Chats | Read Chats Anonymously | gate لمسارات القراءة المحلية/المزامنة | Host integration | يحتاج اختبار النسخة المضيفة |
| Chats | Ghost Typing | gate لحالة input status | Host integration | يحتاج اختبار النسخة المضيفة |
| Appearance | Liquid Glass | إعدادات UI وإعادة رسم المكونات | Host UI | موجود في Host starter |
| Appearance | Color/Gradient/OLED | AppStorage وطبقة Style | Host UI | موجود في Host starter |
| Translation | Language | حفظ locale ثم إعادة تحميل المضيف | Host UI | التخزين موجود، localization الكامل لاحق |
| Developer | @ucorc | بطاقة مطور ورابط Telegram وصورة دائرية | Host UI | موجود في Host starter |

## Public API داخل dylib

تستخدم طبقة Adapter الدوال التالية بدل قراءة متغيرات داخلية مباشرة:

- `tt_product_name` و`tt_version` للهوية والإصدار 1.1.
- `tt_set_enabled` و`tt_is_enabled` لحالة النواة.
- `tt_set_feature_enabled` و`tt_feature_enabled` و`tt_feature_key_at` لحالة الميزات.
- `tt_validate_https_url` قبل إرسال أي رابط إلى URLSession.
- `tt_sanitize_filename` قبل تكوين اسم الملف المؤقت أو المحلي.
- `tt_set_download_stage` و`tt_download_stage_name` لعرض مراحل التنزيل بصراحة.
- `tt_diagnostics_json` لتقرير صغير لا يحتوي أسرارًا أو بيانات المستخدم.

## دورة زر التنزيل

يبدأ الزر بفحص نوع العنصر والرابط. بعد قبول HTTPS ينتقل إلى `TT_DOWNLOAD_VALIDATING` ثم `TT_DOWNLOAD_DOWNLOADING`. ينفذ Adapter الطلب في background، ويكتب إلى ملف مؤقت باسم منظف، ثم يحدد إن كان الناتج صورة أو فيديو. للحفظ في Photos ينتقل إلى `TT_DOWNLOAD_SAVING` وينتظر callback الحقيقي. عند النجاح فقط ينتقل إلى `TT_DOWNLOAD_COMPLETED`، وإلا إلى `TT_DOWNLOAD_FAILED` مع رسالة مناسبة. خيار الصوت يمر عبر `TT_DOWNLOAD_EXTRACTING_AUDIO` ثم يعرض ملف M4A للمشاركة.

## ما لا ينبغي وضعه داخل dylib

لا تضع داخل النواة مفاتيح API أو cookies أو access tokens أو endpoint خاصًا غير موثق. لا تضع فيها حقنًا داخل تطبيق طرف ثالث أو منطقًا يغير التوقيع. لا تعلن أن Read Chats أو Private Profile يعملان خادميًا لمجرد وجود hook محلي؛ يجب التحقق على نسخة المضيف وبجهاز حقيقي.

## معيار الاكتمال

تُعد الميزة مكتملة فقط عندما يملك الزر مسارًا واضحًا، حالة نجاح، حالة فشل، إلغاء أو إعادة محاولة عند الحاجة، سجلاً لا يحتوي بيانات حساسة، وفحصًا على Simulator وجهاز حقيقي في نسخة iOS مستهدفة. إذا لم يتوفر Adapter أو Provider، تظهر الحالة `Not configured` بدل زر يوحي بعمل غير موجود.
