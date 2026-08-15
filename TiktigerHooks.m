#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "substrate.h"
#import "TiktigerPrefs.h"

#pragma mark - Runtime guard and common helpers

typedef void (*TTVoidIMP)(id, SEL);
typedef void (*TTVoidBoolIMP)(id, SEL, BOOL);
typedef void (*TTVoidIDIMP)(id, SEL, id);
typedef BOOL (*TTBoolIMP)(id, SEL);
typedef void (*TTRateIMP)(id, SEL, float);

static BOOL TTInstallCheckedHook(const char *className, const char *selectorName, IMP replacement, IMP *original) {
    Class cls = objc_getClass(className);
    SEL selector = sel_registerName(selectorName);
    if (!cls) { NSLog(@"[Tiktiger] hook skipped: missing class %s", className); return NO; }
    if (!class_getInstanceMethod(cls, selector)) { NSLog(@"[Tiktiger] hook skipped: missing %s %s", className, selectorName); return NO; }
    if (!MSHookMessageEx) { NSLog(@"[Tiktiger] hook skipped: CydiaSubstrate unavailable for %s", selectorName); return NO; }
    MSHookMessageEx(cls, selector, replacement, original);
    NSLog(@"[Tiktiger] hook installed: %s %s", className, selectorName);
    return YES;
}

static UIViewController *TTTopController(void) {
    UIWindow *best = nil;
    for (UIWindow *window in UIApplication.sharedApplication.windows) if (!window.hidden && window.windowLevel == UIWindowLevelNormal && window.rootViewController) { best = window; break; }
    UIViewController *controller = best.rootViewController;
    while (controller.presentedViewController && !controller.presentedViewController.isBeingDismissed) controller = controller.presentedViewController;
    if (controller.navigationController.visibleViewController) controller = controller.navigationController.visibleViewController;
    return controller;
}
static void TTConfirmAction(NSString *title, NSString *message, dispatch_block_t action) {
    dispatch_async(dispatch_get_main_queue(), ^{ UIViewController *presenter = TTTopController(); if (!presenter) return; UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert]; [alert addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]]; [alert addAction:[UIAlertAction actionWithTitle:@"متابعة" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a){ if (action) action(); }]]; [presenter presentViewController:alert animated:YES completion:nil]; });
}
static BOOL TTObjectIsAd(id object) {
    if (!object) return NO;
    @try { return [[object valueForKey:@"isAds"] boolValue]; } @catch (__unused NSException *e) { return NO; }
}
static void TTHideAdViews(UIView *root) {
    if (!root) return;
    id model = nil;
    @try { model = [root valueForKey:@"awemeModel"]; if (!model) model = [root valueForKey:@"model"]; } @catch (__unused NSException *e) {}
    if (TTObjectIsAd(model)) root.hidden = YES;
    for (UIView *child in root.subviews) TTHideAdViews(child);
}
static BOOL TTURLLooksLikeVisit(id candidate) {
    NSString *text = [candidate isKindOfClass:NSString.class] ? candidate : ([candidate isKindOfClass:NSURL.class] ? [(NSURL *)candidate absoluteString] : [candidate description]);
    if (!text.length) return NO;
    NSString *lower = text.lowercaseString;
    return [lower containsString:@"/tiktok/profile/visit/report/"] || [lower containsString:@"/tiktok/story/view/report/"] || [lower containsString:@"/aweme/v1/user/profile/visitor/log/"] || [lower containsString:@"profile/visit"] || [lower containsString:@"visitor/log"];
}

#pragma mark - Confirmed feed and advertising hooks

static IMP TTOrigFeedAppear;
static void TTHookFeedViewDidAppear(id self, SEL _cmd, BOOL animated) {
    if (TTOrigFeedAppear) ((TTVoidBoolIMP)TTOrigFeedAppear)(self, _cmd, animated);
    if (TTBool(@"hideAds")) dispatch_async(dispatch_get_main_queue(), ^{ UIView *view = nil; @try { view = [self valueForKey:@"view"]; } @catch (__unused NSException *e) {} TTHideAdViews(view); });
}
static IMP TTOrigAwemeIsAds;
static BOOL TTHookAwemeIsAds(id self, SEL _cmd) {
    return TTOrigAwemeIsAds ? ((TTBoolIMP)TTOrigAwemeIsAds)(self, _cmd) : NO;
}

#pragma mark - Confirmed like and follow hooks

static IMP TTOrigLikeButton;
static void TTHookLikeButtonClicked(id self, SEL _cmd) {
    if (!TTBool(@"confirmLike")) { if (TTOrigLikeButton) ((TTVoidIMP)TTOrigLikeButton)(self, _cmd); return; }
    TTConfirmAction(@"تأكيد الإعجاب", @"هل تريد الإعجاب بهذا الفيديو؟", ^{ if (TTOrigLikeButton) ((TTVoidIMP)TTOrigLikeButton)(self, _cmd); });
}
static IMP TTOrigFollowButton;
static void TTHookFollowViewClicked(id self, SEL _cmd, id argument) {
    if (!TTBool(@"confirmFollow")) { if (TTOrigFollowButton) ((TTVoidIDIMP)TTOrigFollowButton)(self, _cmd, argument); return; }
    TTConfirmAction(@"تأكيد المتابعة", @"هل تريد متابعة هذا الحساب؟", ^{ if (TTOrigFollowButton) ((TTVoidIDIMP)TTOrigFollowButton)(self, _cmd, argument); });
}

#pragma mark - Confirmed network privacy hook

static IMP TTOrigNetworkBuild;
static id TTHookNetworkBuild(id self, SEL _cmd, id request, id params, id method) {
    if (TTBool(@"anonymousProfiles") && (TTURLLooksLikeVisit(request) || TTURLLooksLikeVisit(params))) { NSLog(@"[Tiktiger] blocked profile/story visit report"); return nil; }
    return TTOrigNetworkBuild ? ((id (*)(id, SEL, id, id, id))TTOrigNetworkBuild)(self, _cmd, request, params, method) : nil;
}

#pragma mark - Confirmed story, playback and optional loop selectors

static IMP TTOrigStoryRead;
static void TTHookStoryMarkRead(id self, SEL _cmd, id story) {
    if (TTBool(@"unseenStories")) { NSLog(@"[Tiktiger] kept story unread"); return; }
    if (TTOrigStoryRead) ((TTVoidIDIMP)TTOrigStoryRead)(self, _cmd, story);
}
static IMP TTOrigRate;
static void TTHookSetRate(id self, SEL _cmd, float rate) {
    if (TTBool(@"persistentSpeed")) rate = (float)TTNumber(@"playbackSpeed", 1.0);
    if (TTOrigRate) ((TTRateIMP)TTOrigRate)(self, _cmd, rate);
}
static IMP TTOrigLoopSetter;
static void TTHookSetIsLoop(id self, SEL _cmd, BOOL value) {
    if (TTBool(@"stopReplay")) value = NO;
    if (TTOrigLoopSetter) ((TTVoidBoolIMP)TTOrigLoopSetter)(self, _cmd, value);
}

#pragma mark - Installation

void TTInstallRuntimeHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TTInstallCheckedHook("AWEFeedContainerViewController", "viewDidAppear:", (IMP)TTHookFeedViewDidAppear, &TTOrigFeedAppear);
        TTInstallCheckedHook("AWEAwemeModel", "isAds", (IMP)TTHookAwemeIsAds, &TTOrigAwemeIsAds);
        TTInstallCheckedHook("AWEPlayInteractionLikeElement", "buttonClicked", (IMP)TTHookLikeButtonClicked, &TTOrigLikeButton);
        TTInstallCheckedHook("AWEPlayInteractionUserAvatarElementViewModel", "onFollowViewClicked:", (IMP)TTHookFollowViewClicked, &TTOrigFollowButton);
        TTInstallCheckedHook("TTNetworkManagerChromium", "buildJSONHttpTask:params:method:", (IMP)TTHookNetworkBuild, &TTOrigNetworkBuild);
        TTInstallCheckedHook("TTKStoryManager", "markStoryReaded:", (IMP)TTHookStoryMarkRead, &TTOrigStoryRead);
        TTInstallCheckedHook("TTKMainOwnPlayer", "setRate:", (IMP)TTHookSetRate, &TTOrigRate);
        TTInstallCheckedHook("AWEVideoPlayerController", "setIsLoop:", (IMP)TTHookSetIsLoop, &TTOrigLoopSetter);
    });
}

__attribute__((constructor)) static void TiktigerHooksConstructor(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ TTInstallRuntimeHooks(); });
}
