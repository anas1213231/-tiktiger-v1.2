#import <Foundation/Foundation.h>

#import "Tiktiger.h"

NS_ASSUME_NONNULL_BEGIN

@interface TiktigerHostAdapter : NSObject

- (BOOL)validateDirectMediaURL:(NSURL *)url;
- (BOOL)setFeature:(NSString *)featureKey enabled:(BOOL)enabled;
- (BOOL)isFeatureEnabled:(NSString *)featureKey;
- (NSString *)safeFilenameForName:(NSString *)name;
- (void)setDownloadStage:(TTDownloadStage)stage;
- (NSString *)downloadStageName;
- (NSString *)diagnosticsJSON;

@end

NS_ASSUME_NONNULL_END
