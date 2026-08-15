#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "TiktigerPrefs.h"

void ttOpenSettings(id self, SEL _cmd) {
    TTShowSettings((UIViewController *)self);
}

void ttDownloadVideo(id self, SEL _cmd) {
    id model = nil;
    @try { model = [self valueForKey:@"awemeModel"]; } @catch (NSException *e) {}
    TTDownloadMedia(TTExtractMediaURL(model), (UIViewController *)self, TTBool(@"showShareAfterDownload"));
}
