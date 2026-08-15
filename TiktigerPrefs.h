#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSArray *TTFeatureSections(void);
FOUNDATION_EXPORT BOOL TTBool(NSString *key);
FOUNDATION_EXPORT void TTSetBool(NSString *key, BOOL value);
FOUNDATION_EXPORT double TTNumber(NSString *key, double fallback);
FOUNDATION_EXPORT void TTSetNumber(NSString *key, double value);
FOUNDATION_EXPORT NSString *TTString(NSString *key, NSString *fallback);
FOUNDATION_EXPORT NSURL *TTExtractMediaURL(id object);
FOUNDATION_EXPORT void TTSaveImage(UIImage *image);
FOUNDATION_EXPORT void TTDownloadMedia(NSURL *url, UIViewController *presenter, BOOL shareAfter);
FOUNDATION_EXPORT void TTConfirm(UIViewController *presenter, NSString *title, NSString *message, void (^accept)(void));
FOUNDATION_EXPORT void TTShowSettings(UIViewController *presenter);
