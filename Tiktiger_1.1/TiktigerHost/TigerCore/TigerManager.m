#import "TigerManager.h"

static NSString * const kTiktigerFeaturePrefix = @"tiktiger.feature.";
static NSString * const kTiktigerEnabledKey = @"tiktiger.master.enabled";

@interface TigerManager ()
@property (nonatomic, assign) NSUInteger counter;
@end

@implementation TigerManager

@synthesize enabled = _enabled;

+ (TigerManager *)shared {
    static TigerManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TigerManager alloc] init];
        if (NSUserDefaults.standardUserDefaults.objectForKey(kTiktigerEnabledKey) == nil) {
            [NSUserDefaults.standardUserDefaults setBool:YES forKey:kTiktigerEnabledKey];
        }
        manager.enabled = [NSUserDefaults.standardUserDefaults boolForKey:kTiktigerEnabledKey];
    });
    return manager;
}

- (BOOL)isEnabled {
    if (NSUserDefaults.standardUserDefaults.objectForKey(kTiktigerEnabledKey) == nil) {
        return _enabled;
    }
    return [NSUserDefaults.standardUserDefaults boolForKey:kTiktigerEnabledKey];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kTiktigerEnabledKey];
}

- (NSString *)version {
    return @"1.1";
}

- (NSString *)statusText {
    return self.isEnabled ? @"Tiktiger 1.1 is ready" : @"Tiktiger 1.1 is disabled";
}

- (NSString *)uppercaseText:(NSString *)text {
    return text.uppercaseString;
}

- (NSUInteger)incrementCounter {
    self.counter += 1;
    return self.counter;
}

- (void)resetCounter {
    self.counter = 0;
}

- (BOOL)featureEnabledForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    NSString *defaultsKey = [kTiktigerFeaturePrefix stringByAppendingString:key];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults objectForKey:defaultsKey] == nil) {
        return defaultValue;
    }
    return [defaults boolForKey:defaultsKey];
}

- (void)setFeatureEnabled:(BOOL)enabled forKey:(NSString *)key {
    NSString *defaultsKey = [kTiktigerFeaturePrefix stringByAppendingString:key];
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:defaultsKey];
}

- (NSArray<NSString *> *)storedFeatureKeys {
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    NSDictionary *all = NSUserDefaults.standardUserDefaults.dictionaryRepresentation;
    for (NSString *key in all) {
        if ([key hasPrefix:kTiktigerFeaturePrefix]) {
            [keys addObject:[key substringFromIndex:kTiktigerFeaturePrefix.length]];
        }
    }
    return [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

@end
