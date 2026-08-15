#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <SafariServices/SafariServices.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "TiktigerPrefs.h"

static BOOL (*orig_openURL)(id, SEL, id, id, id);
static BOOL new_openURL(id self, SEL _cmd, NSURL *url, NSDictionary *opts, id handler) {
    if (TTBool(@"openInSafari") && url) {
        UIViewController *root = [[UIApplication sharedApplication].keyWindow rootViewController];
        SFSafariViewController *sf = [[SFSafariViewController alloc] initWithURL:url];
        [root presentViewController:sf animated:YES completion:nil];
        return YES;
    }
    return orig_openURL(self, _cmd, url, opts, handler);
}

static void (*orig_setRate)(id, SEL, float);
static void new_setRate(id self, SEL _cmd, float rate) {
    if (TTBool(@"persistentSpeed")) {
        rate = TTNumber(@"playbackSpeed", 1.0);
    }
    orig_setRate(self, _cmd, rate);
}

static void (*orig_appDidBecomeActive)(id, SEL, id);
static void new_appDidBecomeActive(id self, SEL _cmd, id notif) {
    orig_appDidBecomeActive(self, _cmd, notif);
    if (TTBool(@"appLock")) {
        LAContext *ctx = [[LAContext alloc] init];
        NSError *err = nil;
        if ([ctx canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&err]) {
            [ctx evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"Tiktiger" reply:^(BOOL ok, NSError *e){
                if (!ok) {
                    dispatch_async(dispatch_get_main_queue(), ^{ exit(0); });
                }
            }];
        }
    }
}

__attribute__((constructor)) static void TiktigerMiscInit(void) {
    Class app = objc_getClass("UIApplication");
    if (app) {
        MSHookMessageEx(app, @selector(openURL:options:completionHandler:), (IMP)new_openURL, (IMP *)&orig_openURL);
    }
    Class player = objc_getClass("AVPlayer");
    if (player) {
        MSHookMessageEx(player, @selector(setRate:), (IMP)new_setRate, (IMP *)&orig_setRate);
    }
    Class appDel = objc_getClass("AWELaunchingDelegate");
    if (appDel) {
        MSHookMessageEx(appDel, @selector(applicationDidBecomeActive:), (IMP)new_appDidBecomeActive, (IMP *)&orig_appDidBecomeActive);
    }
}
