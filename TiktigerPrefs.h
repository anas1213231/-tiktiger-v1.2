#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSArray<NSDictionary *> *TTPrivacyFeatureDefinitions(void);
FOUNDATION_EXPORT BOOL TTBool(NSString *key);
FOUNDATION_EXPORT void TTSetBool(NSString *key, BOOL value);
FOUNDATION_EXPORT BOOL TTArabicLanguage(void);
FOUNDATION_EXPORT void TTSetArabicLanguage(BOOL arabic);
FOUNDATION_EXPORT void TTResetPrivacySettings(void);
