#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TigerManager : NSObject

@property (class, nonatomic, readonly) TigerManager *shared;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, copy, readonly) NSString *version;

- (NSString *)statusText;
- (NSString *)uppercaseText:(NSString *)text;
- (NSUInteger)incrementCounter;
- (void)resetCounter;

/// Centralized feature state shared by the host UI and the framework.
- (BOOL)featureEnabledForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (void)setFeatureEnabled:(BOOL)enabled forKey:(NSString *)key;
- (NSArray<NSString *> *)storedFeatureKeys;

@end

NS_ASSUME_NONNULL_END
