#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "substrate.h"
#import "TiktigerPrefs.h"

static void (*orig_setRead)(id, SEL, BOOL);
static void new_setRead(id self, SEL _cmd, BOOL read) {
    if (TTBool(@"unreadMessages")) read = NO;
    orig_setRead(self, _cmd, read);
}

static void (*orig_sendTyping)(id, SEL, BOOL);
static void new_sendTyping(id self, SEL _cmd, BOOL typing) {
    if (TTBool(@"hideTyping")) return;
    orig_sendTyping(self, _cmd, typing);
}

static void (*orig_sendMessage)(id, SEL, id);
static void new_sendMessage(id self, SEL _cmd, id message) {
    orig_sendMessage(self, _cmd, message);
    if (TTBool(@"repeatMessages")) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            orig_sendMessage(self, _cmd, message);
        });
    }
}

__attribute__((constructor)) static void TiktigerMessagesInit(void) {
    Class msgCell = objc_getClass("AWEIMMessageCellNode");
    if (msgCell) {
        MSHookMessageEx(msgCell, @selector(setRead:), (IMP)new_setRead, (IMP *)&orig_setRead);
    }
    Class chatVC = objc_getClass("AWEIMChatViewController");
    if (chatVC) {
        MSHookMessageEx(chatVC, @selector(sendTypingIndicator:), (IMP)new_sendTyping, (IMP *)&orig_sendTyping);
        MSHookMessageEx(chatVC, @selector(sendMessage:), (IMP)new_sendMessage, (IMP *)&orig_sendMessage);
    }
}
