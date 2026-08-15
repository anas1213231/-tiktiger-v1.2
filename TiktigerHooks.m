#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "substrate.h"
#import "TiktigerPrefs.h"

typedef void (*TTVoidIMP)(id, SEL);
typedef void (*TTVoidIDIMP)(id, SEL, id);
typedef void (*TTVoidBoolIMP)(id, SEL, BOOL);
typedef void (*TTRateIMP)(id, SEL, float);

static BOOL TTInstallCheckedHook(const char *className, const char *selectorName, IMP replacement, IMP *original) {
    Class cls = objc_getClass(className);
    SEL selector = sel_registerName(selectorName);
    if (!cls) { NSLog(@"[Tiktiger] hook skipped: missing class %s", className); return NO; }
    if (!class_getInstanceMethod(cls, selector)) { NSLog(@"[Tiktiger] hook skipped: missing %s %s", className, selectorName); return NO; }
    if (!MSHookMessageEx) { NSLog(@"[Tiktiger] hook skipped: CydiaSubstrate unavailable"); return NO; }
    MSHookMessageEx(cls, selector, replacement, original);
    NSLog(@"[Tiktiger] hook installed: %s %s", className, selectorName);
    return YES;
}

static UIViewController *TTTopController(void) {
    UIWindow *candidate = nil;
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (!window.hidden && window.windowLevel == UIWindowLevelNormal && window.rootViewController) { candidate = window; break; }
    }
    UIViewController *controller = candidate.rootViewController;
    while (controller.presentedViewController && !controller.presentedViewController.isBeingDismissed) controller = controller.presentedViewController;
    if (controller.navigationController.visibleViewController) controller = controller.navigationController.visibleViewController;
    return controller;
}
static void TTConfirmSafe(NSString *title, NSString *message, dispatch_block_t accept) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *presenter = TTTopController();
        if (!presenter) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"متابعة" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action){ if (accept) accept(); }]];
        [presenter presentViewController:alert animated:YES completion:nil];
    });
}

static IMP TTOriginalLike;
static void TTHookLike(id self, SEL _cmd) {
    if (!TTBool(@"confirmLike")) { if (TTOriginalLike) ((TTVoidIMP)TTOriginalLike)(self, _cmd); return; }
    TTConfirmSafe(@"تأكيد الإعجاب", @"هل تريد الإعجاب بهذا الفيديو؟", ^{ if (TTOriginalLike) ((TTVoidIMP)TTOriginalLike)(self, _cmd); });
}

static IMP TTOriginalFollow;
static void TTHookFollow(id self, SEL _cmd, id argument) {
    if (!TTBool(@"confirmFollow")) { if (TTOriginalFollow) ((TTVoidIDIMP)TTOriginalFollow)(self, _cmd, argument); return; }
    TTConfirmSafe(@"تأكيد المتابعة", @"هل تريد متابعة هذا الحساب؟", ^{ if (TTOriginalFollow) ((TTVoidIDIMP)TTOriginalFollow)(self, _cmd, argument); });
}

static IMP TTOriginalStoryRead;
static void TTHookStoryRead(id self, SEL _cmd, id story) {
    if (TTBool(@"unseenStories")) { NSLog(@"[Tiktiger] story read report suppressed"); return; }
    if (TTOriginalStoryRead) ((TTVoidIDIMP)TTOriginalStoryRead)(self, _cmd, story);
}

static IMP TTOriginalRate;
static void TTHookSetRate(id self, SEL _cmd, float rate) {
    if (TTBool(@"persistentSpeed")) rate = (float)TTNumber(@"playbackSpeed", 1.0);
    if (TTOriginalRate) ((TTRateIMP)TTOriginalRate)(self, _cmd, rate);
}

static IMP TTOriginalLoop;
static void TTHookSetIsLoop(id self, SEL _cmd, BOOL value) {
    if (TTBool(@"stopReplay")) value = NO;
    if (TTOriginalLoop) ((TTVoidBoolIMP)TTOriginalLoop)(self, _cmd, value);
}

void TTInstallRuntimeHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TTInstallCheckedHook("AWEPlayInteractionLikeElement", "buttonClicked", (IMP)TTHookLike, &TTOriginalLike);
        TTInstallCheckedHook("AWEPlayInteractionUserAvatarElementViewModel", "onFollowViewClicked:", (IMP)TTHookFollow, &TTOriginalFollow);
        TTInstallCheckedHook("TTKStoryManager", "markStoryReaded:", (IMP)TTHookStoryRead, &TTOriginalStoryRead);
        TTInstallCheckedHook("TTKMainOwnPlayer", "setRate:", (IMP)TTHookSetRate, &TTOriginalRate);
        TTInstallCheckedHook("AWEVideoPlayerController", "setIsLoop:", (IMP)TTHookSetIsLoop, &TTOriginalLoop);
    });
}

__attribute__((constructor)) static void TiktigerHooksConstructor(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ TTInstallRuntimeHooks(); });
}
