#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "substrate.h"
#import "TiktigerPrefs.h"

typedef void (*TTVoidIMP)(id, SEL);
typedef void (*TTVoidIDIMP)(id, SEL, id);
typedef void (*TTVoidBoolIMP)(id, SEL, BOOL);
typedef BOOL (*TTBoolIMP)(id, SEL);
typedef BOOL (*TTBoolIDIMP)(id, SEL, id);
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

/* Existing feature hooks. */
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
    if (TTBool(@"unseenStories")) { NSLog(@"[Tiktiger][Privacy] Keep Story Unseen: story read report suppressed"); return; }
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

/* New feature 1: Anonymous Profile Visits. */
static IMP TTOriginalProfileDecision;
static BOOL TTHookProfileDecision(id self, SEL _cmd) {
    if (TTBool(@"anonymousProfiles")) return NO;
    return TTOriginalProfileDecision ? ((TTBoolIMP)TTOriginalProfileDecision)(self, _cmd) : NO;
}

static IMP TTOriginalProfileDecisionForUser;
static BOOL TTHookProfileDecisionForUser(id self, SEL _cmd, id user) {
    if (TTBool(@"anonymousProfiles")) return NO;
    return TTOriginalProfileDecisionForUser ? ((TTBoolIDIMP)TTOriginalProfileDecisionForUser)(self, _cmd, user) : NO;
}

static IMP TTOriginalProfileReport;
static void TTHookProfileReport(id self, SEL _cmd) {
    if (TTBool(@"anonymousProfiles")) { NSLog(@"[Tiktiger][Privacy] Anonymous Profile Visits: profile report suppressed"); return; }
    if (TTOriginalProfileReport) ((TTVoidIMP)TTOriginalProfileReport)(self, _cmd);
}

/* New feature 2: Keep Story Unseen. This supports both the old repository target and the analyzed candidate target. */
static IMP TTOriginalStoryMarkAsRead;
static void TTHookStoryMarkAsRead(id self, SEL _cmd, id story) {
    if (TTBool(@"unseenStories")) { NSLog(@"[Tiktiger][Privacy] Keep Story Unseen: markAsRead suppressed"); return; }
    if (TTOriginalStoryMarkAsRead) ((TTVoidIDIMP)TTOriginalStoryMarkAsRead)(self, _cmd, story);
}

/* New feature 3: Keep Messages Unseen. Only read-receipt sync paths are suppressed. */
static IMP TTOriginalMessageReadDebounce;
static void TTHookMessageReadDebounce(id self, SEL _cmd) {
    if (TTBool(@"unreadMessages")) { NSLog(@"[Tiktiger][Privacy] Keep Messages Unseen: read sync suppressed"); return; }
    if (TTOriginalMessageReadDebounce) ((TTVoidIMP)TTOriginalMessageReadDebounce)(self, _cmd);
}

static IMP TTOriginalMessageReadSync;
static void TTHookMessageReadSync(id self, SEL _cmd, id message) {
    if (TTBool(@"unreadMessages")) { NSLog(@"[Tiktiger][Privacy] Keep Messages Unseen: message read sync suppressed"); return; }
    if (TTOriginalMessageReadSync) ((TTVoidIDIMP)TTOriginalMessageReadSync)(self, _cmd, message);
}

/* New feature 4: Hide Typing. Candidate selectors are independently guarded for host-version differences. */
static IMP TTOriginalTypingNoArgs;
static void TTHookTypingNoArgs(id self, SEL _cmd) {
    if (TTBool(@"hideTyping")) { NSLog(@"[Tiktiger][Privacy] Hide Typing: typing event suppressed"); return; }
    if (TTOriginalTypingNoArgs) ((TTVoidIMP)TTOriginalTypingNoArgs)(self, _cmd);
}

static IMP TTOriginalTypingControllerBool;
static void TTHookTypingControllerBool(id self, SEL _cmd, BOOL isTyping) {
    if (TTBool(@"hideTyping")) { NSLog(@"[Tiktiger][Privacy] Hide Typing: typing event suppressed"); return; }
    if (TTOriginalTypingControllerBool) ((TTVoidBoolIMP)TTOriginalTypingControllerBool)(self, _cmd, isTyping);
}

static IMP TTOriginalTypingControllerStatus;
static void TTHookTypingControllerStatus(id self, SEL _cmd, id status) {
    if (TTBool(@"hideTyping")) { NSLog(@"[Tiktiger][Privacy] Hide Typing: typing status suppressed"); return; }
    if (TTOriginalTypingControllerStatus) ((TTVoidIDIMP)TTOriginalTypingControllerStatus)(self, _cmd, status);
}

static IMP TTOriginalTypingSenderBool;
static void TTHookTypingSenderBool(id self, SEL _cmd, BOOL isTyping) {
    if (TTBool(@"hideTyping")) { NSLog(@"[Tiktiger][Privacy] Hide Typing: typing event suppressed"); return; }
    if (TTOriginalTypingSenderBool) ((TTVoidBoolIMP)TTOriginalTypingSenderBool)(self, _cmd, isTyping);
}

static IMP TTOriginalTypingSenderStatus;
static void TTHookTypingSenderStatus(id self, SEL _cmd, id status) {
    if (TTBool(@"hideTyping")) { NSLog(@"[Tiktiger][Privacy] Hide Typing: typing status suppressed"); return; }
    if (TTOriginalTypingSenderStatus) ((TTVoidIDIMP)TTOriginalTypingSenderStatus)(self, _cmd, status);
}

void TTInstallRuntimeHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /* Existing hooks. */
        TTInstallCheckedHook("AWEPlayInteractionLikeElement", "buttonClicked", (IMP)TTHookLike, &TTOriginalLike);
        TTInstallCheckedHook("AWEPlayInteractionUserAvatarElementViewModel", "onFollowViewClicked:", (IMP)TTHookFollow, &TTOriginalFollow);
        TTInstallCheckedHook("TTKStoryManager", "markStoryReaded:", (IMP)TTHookStoryRead, &TTOriginalStoryRead);
        TTInstallCheckedHook("TTKMainOwnPlayer", "setRate:", (IMP)TTHookSetRate, &TTOriginalRate);
        TTInstallCheckedHook("AWEVideoPlayerController", "setIsLoop:", (IMP)TTHookSetIsLoop, &TTOriginalLoop);

        /* Anonymous Profile Visits. */
        TTInstallCheckedHook("TTKProfileViewsVisitor", "p_shouldReportProfileView", (IMP)TTHookProfileDecision, &TTOriginalProfileDecision);
        TTInstallCheckedHook("TTKProfileViewsVisitor", "p_shouldReportHasVeiwedProfileForUser:", (IMP)TTHookProfileDecisionForUser, &TTOriginalProfileDecisionForUser);
        TTInstallCheckedHook("TTKProfileViewsVisitor", "reportProfileView", (IMP)TTHookProfileReport, &TTOriginalProfileReport);

        /* Keep Story Unseen candidate. */
        TTInstallCheckedHook("TTKStoryMarkReadService", "markAsRead:", (IMP)TTHookStoryMarkAsRead, &TTOriginalStoryMarkAsRead);

        /* Keep Messages Unseen candidates. */
        TTInstallCheckedHook("AWEIMMessageReadComponent", "p_debounceMarkReadSyncToServer", (IMP)TTHookMessageReadDebounce, &TTOriginalMessageReadDebounce);
        TTInstallCheckedHook("AWEIMMessageReadComponent", "p_markReadSyncToServerWithMessage:", (IMP)TTHookMessageReadSync, &TTOriginalMessageReadSync);

        /* Hide Typing candidates. */
        TTInstallCheckedHook("AWEIMSendMessageController", "sendTyping", (IMP)TTHookTypingNoArgs, &TTOriginalTypingNoArgs);
        TTInstallCheckedHook("AWEIMSendMessageController", "sendTyping:", (IMP)TTHookTypingControllerBool, &TTOriginalTypingControllerBool);
        TTInstallCheckedHook("AWEIMSendMessageController", "sendTypingStatus:", (IMP)TTHookTypingControllerStatus, &TTOriginalTypingControllerStatus);
        TTInstallCheckedHook("AWEIMChatRoomMessageSender", "sendTyping:", (IMP)TTHookTypingSenderBool, &TTOriginalTypingSenderBool);
        TTInstallCheckedHook("AWEIMChatRoomMessageSender", "sendTypingStatus:", (IMP)TTHookTypingSenderStatus, &TTOriginalTypingSenderStatus);
    });
}

__attribute__((constructor)) static void TiktigerHooksConstructor(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ TTInstallRuntimeHooks(); });
}
