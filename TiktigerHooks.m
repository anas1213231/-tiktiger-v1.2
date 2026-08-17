#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "substrate.h"
#import "TiktigerPrefs.h"

typedef BOOL (*TTBoolIMP)(id, SEL);
typedef BOOL (*TTBoolIDIMP)(id, SEL, id);
typedef void (*TTVoidIMP)(id, SEL);
typedef void (*TTVoidIDIMP)(id, SEL, id);
typedef void (*TTVoidBoolIMP)(id, SEL, BOOL);

static BOOL TTInstallCheckedHook(const char *className, const char *selectorName, IMP replacement, IMP *original) {
    Class cls = objc_getClass(className);
    SEL selector = sel_registerName(selectorName);
    if (!cls) {
        NSLog(@"[Tiktiger v2] skipped missing class: %s", className);
        return NO;
    }
    if (!class_getInstanceMethod(cls, selector)) {
        NSLog(@"[Tiktiger v2] skipped missing selector: %s %s", className, selectorName);
        return NO;
    }
    if (!MSHookMessageEx) {
        NSLog(@"[Tiktiger v2] skipped because CydiaSubstrate is unavailable");
        return NO;
    }
    MSHookMessageEx(cls, selector, replacement, original);
    NSLog(@"[Tiktiger v2] installed: %s %s", className, selectorName);
    return YES;
}

/* Anonymous Profile Visits */
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
    if (TTBool(@"anonymousProfiles")) return;
    if (TTOriginalProfileReport) ((TTVoidIMP)TTOriginalProfileReport)(self, _cmd);
}

/* Keep Story Unseen */
static IMP TTOriginalStoryRead;
static void TTHookStoryRead(id self, SEL _cmd, id story) {
    if (TTBool(@"unseenStories")) return;
    if (TTOriginalStoryRead) ((TTVoidIDIMP)TTOriginalStoryRead)(self, _cmd, story);
}

static IMP TTOriginalStoryMarkAsRead;
static void TTHookStoryMarkAsRead(id self, SEL _cmd, id story) {
    if (TTBool(@"unseenStories")) return;
    if (TTOriginalStoryMarkAsRead) ((TTVoidIDIMP)TTOriginalStoryMarkAsRead)(self, _cmd, story);
}

/* Keep Messages Unseen */
static IMP TTOriginalMessageReadDebounce;
static void TTHookMessageReadDebounce(id self, SEL _cmd) {
    if (TTBool(@"unreadMessages")) return;
    if (TTOriginalMessageReadDebounce) ((TTVoidIMP)TTOriginalMessageReadDebounce)(self, _cmd);
}

static IMP TTOriginalMessageReadSync;
static void TTHookMessageReadSync(id self, SEL _cmd, id message) {
    if (TTBool(@"unreadMessages")) return;
    if (TTOriginalMessageReadSync) ((TTVoidIDIMP)TTOriginalMessageReadSync)(self, _cmd, message);
}

/* Hide Typing */
static IMP TTOriginalTypingNoArgs;
static void TTHookTypingNoArgs(id self, SEL _cmd) {
    if (TTBool(@"hideTyping")) return;
    if (TTOriginalTypingNoArgs) ((TTVoidIMP)TTOriginalTypingNoArgs)(self, _cmd);
}

static IMP TTOriginalTypingControllerBool;
static void TTHookTypingControllerBool(id self, SEL _cmd, BOOL isTyping) {
    if (TTBool(@"hideTyping")) return;
    if (TTOriginalTypingControllerBool) ((TTVoidBoolIMP)TTOriginalTypingControllerBool)(self, _cmd, isTyping);
}

static IMP TTOriginalTypingControllerStatus;
static void TTHookTypingControllerStatus(id self, SEL _cmd, id status) {
    if (TTBool(@"hideTyping")) return;
    if (TTOriginalTypingControllerStatus) ((TTVoidIDIMP)TTOriginalTypingControllerStatus)(self, _cmd, status);
}

static IMP TTOriginalTypingSenderBool;
static void TTHookTypingSenderBool(id self, SEL _cmd, BOOL isTyping) {
    if (TTBool(@"hideTyping")) return;
    if (TTOriginalTypingSenderBool) ((TTVoidBoolIMP)TTOriginalTypingSenderBool)(self, _cmd, isTyping);
}

static IMP TTOriginalTypingSenderStatus;
static void TTHookTypingSenderStatus(id self, SEL _cmd, id status) {
    if (TTBool(@"hideTyping")) return;
    if (TTOriginalTypingSenderStatus) ((TTVoidIDIMP)TTOriginalTypingSenderStatus)(self, _cmd, status);
}

void TTInstallRuntimeHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TTInstallCheckedHook("TTKProfileViewsVisitor", "p_shouldReportProfileView", (IMP)TTHookProfileDecision, &TTOriginalProfileDecision);
        TTInstallCheckedHook("TTKProfileViewsVisitor", "p_shouldReportHasVeiwedProfileForUser:", (IMP)TTHookProfileDecisionForUser, &TTOriginalProfileDecisionForUser);
        TTInstallCheckedHook("TTKProfileViewsVisitor", "reportProfileView", (IMP)TTHookProfileReport, &TTOriginalProfileReport);

        TTInstallCheckedHook("TTKStoryManager", "markStoryReaded:", (IMP)TTHookStoryRead, &TTOriginalStoryRead);
        TTInstallCheckedHook("TTKStoryMarkReadService", "markAsRead:", (IMP)TTHookStoryMarkAsRead, &TTOriginalStoryMarkAsRead);

        TTInstallCheckedHook("AWEIMMessageReadComponent", "p_debounceMarkReadSyncToServer", (IMP)TTHookMessageReadDebounce, &TTOriginalMessageReadDebounce);
        TTInstallCheckedHook("AWEIMMessageReadComponent", "p_markReadSyncToServerWithMessage:", (IMP)TTHookMessageReadSync, &TTOriginalMessageReadSync);

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
