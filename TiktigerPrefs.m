#import "TiktigerPrefs.h"

static NSString * const kTTPreferencePrefix = @"Tiktiger.v2.";
static NSString * const kTTArabicLanguageKey = @"Tiktiger.v2.languageArabic";

static NSString *TTKey(NSString *key) {
    return [kTTPreferencePrefix stringByAppendingString:key ?: @""];
}

BOOL TTBool(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:TTKey(key)];
}

void TTSetBool(NSString *key, BOOL value) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setBool:value forKey:TTKey(key)];
    [defaults synchronize];
}

BOOL TTArabicLanguage(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults objectForKey:kTTArabicLanguageKey] == nil) return YES;
    return [defaults boolForKey:kTTArabicLanguageKey];
}

void TTSetArabicLanguage(BOOL arabic) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setBool:arabic forKey:kTTArabicLanguageKey];
    [defaults synchronize];
}

NSArray<NSDictionary *> *TTPrivacyFeatureDefinitions(void) {
    return @[
        @{
            @"key": @"anonymousProfiles",
            @"titleAR": @"زيارات ملف مجهولة",
            @"titleEN": @"Anonymous Profile Visits",
            @"detailAR": @"تمنع إرسال إشعار زيارة الملف عند تفعيلها.",
            @"detailEN": @"Suppresses profile-visit reporting while enabled.",
            @"icon": @"person.crop.circle.badge.xmark",
            @"accent": @"#56D6C7"
        },
        @{
            @"key": @"unseenStories",
            @"titleAR": @"مشاهدة الستوري دون ظهور",
            @"titleEN": @"Keep Story Unseen",
            @"detailAR": @"تحافظ على حالة الستوري غير مشاهدة.",
            @"detailEN": @"Keeps story read state unchanged.",
            @"icon": @"circle.dashed",
            @"accent": @"#8D7CFF"
        },
        @{
            @"key": @"unreadMessages",
            @"titleAR": @"الرسائل غير مقروءة",
            @"titleEN": @"Keep Messages Unseen",
            @"detailAR": @"توقف مزامنة إيصال قراءة الرسائل.",
            @"detailEN": @"Suppresses message-read receipt synchronization.",
            @"icon": @"envelope.badge",
            @"accent": @"#FF8A72"
        },
        @{
            @"key": @"hideTyping",
            @"titleAR": @"إخفاء حالة الكتابة",
            @"titleEN": @"Hide Typing",
            @"detailAR": @"يمنع إرسال مؤشر جارٍ بالكتابة.",
            @"detailEN": @"Suppresses typing-status events.",
            @"icon": @"ellipsis.bubble",
            @"accent": @"#F5C96A"
        }
    ];
}

void TTResetPrivacySettings(void) {
    for (NSDictionary *feature in TTPrivacyFeatureDefinitions()) {
        TTSetBool(feature[@"key"], NO);
    }
}
