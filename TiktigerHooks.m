#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <AVFoundation/AVFoundation.h>
#import "substrate.h"
#import "TiktigerPrefs.h"

static BOOL TTInstallHook(const char *className, SEL selector, IMP replacement, IMP *original, const char *label) {
    Class cls = objc_getClass(className);
    if (!cls) { NSLog(@"[Tiktiger] hook skipped: %s class missing", label); return NO; }
    if (!class_getInstanceMethod(cls, selector)) { NSLog(@"[Tiktiger] hook skipped: %s selector missing", label); return NO; }
    if (!MSHookMessageEx) { NSLog(@"[Tiktiger] hook skipped: substrate unavailable (%s)", label); return NO; }
    MSHookMessageEx(cls, selector, replacement, original);
    NSLog(@"[Tiktiger] hook installed: %s", label);
    return YES;
}

static IMP TTOrigFeedAppear;
static void TTHookFeedAppear(id self, SEL _cmd, BOOL animated) { if (TTOrigFeedAppear) ((void (*)(id, SEL, BOOL))TTOrigFeedAppear)(self, _cmd, animated); }
static IMP TTOrigFeedRefresh;
static void TTHookFeedRefresh(id self, SEL _cmd) { if (!TTBool(@"disableRefresh") && TTOrigFeedRefresh) ((void (*)(id, SEL))TTOrigFeedRefresh)(self, _cmd); }
static IMP TTOrigFeedModel;
static void TTHookFeedModel(id self, SEL _cmd, id model) {
    BOOL isAd = NO;
    @try { isAd = [[model valueForKey:@"isAd"] boolValue] || [[model valueForKey:@"isAdvert"] boolValue]; } @catch (__unused NSException *exception) {}
    if (TTBool(@"hideAds") && isAd) { UIView *view = [self isKindOfClass:UIViewController.class] ? [self view] : nil; view.hidden = YES; }
    if (TTOrigFeedModel) ((void (*)(id, SEL, id))TTOrigFeedModel)(self, _cmd, model);
}
static IMP TTOrigSensitive;
static BOOL TTHookSensitive(id self, SEL _cmd) { if (TTBool(@"disableSensitiveFilter")) return NO; return TTOrigSensitive ? ((BOOL (*)(id, SEL))TTOrigSensitive)(self, _cmd) : NO; }
static IMP TTOrigLoop;
static BOOL TTHookLoop(id self, SEL _cmd) { if (TTBool(@"stopReplay")) return NO; return TTOrigLoop ? ((BOOL (*)(id, SEL))TTOrigLoop)(self, _cmd) : NO; }
static IMP TTOrigForceHD;
static BOOL TTHookForceHD(id self, SEL _cmd) { if (TTBool(@"highQualityUpload") || TTBool(@"directHDDownload")) return YES; return TTOrigForceHD ? ((BOOL (*)(id, SEL))TTOrigForceHD)(self, _cmd) : NO; }
static IMP TTOrigStoryAppear;
static void TTHookStoryAppear(id self, SEL _cmd, BOOL animated) { if (TTOrigStoryAppear) ((void (*)(id, SEL, BOOL))TTOrigStoryAppear)(self, _cmd, animated); }
static IMP TTOrigMessageRead;
static void TTHookMessageRead(id self, SEL _cmd, BOOL read) { if (TTBool(@"unreadMessages")) read = NO; if (TTOrigMessageRead) ((void (*)(id, SEL, BOOL))TTOrigMessageRead)(self, _cmd, read); }
static IMP TTOrigTyping;
static void TTHookTyping(id self, SEL _cmd, BOOL typing) { if (!TTBool(@"hideTyping") && TTOrigTyping) ((void (*)(id, SEL, BOOL))TTOrigTyping)(self, _cmd, typing); }
static IMP TTOrigPlayerRate;
static void TTHookPlayerRate(id self, SEL _cmd, float rate) { if (TTBool(@"persistentSpeed")) rate = (float)TTNumber(@"playbackSpeed", 1.0); if (TTOrigPlayerRate) ((void (*)(id, SEL, float))TTOrigPlayerRate)(self, _cmd, rate); }
static IMP TTOrigUpload;
static void TTHookUpload(id self, SEL _cmd) { if (TTBool(@"highQualityUpload")) { @try { [self setValue:@YES forKey:@"forceHD"]; [self setValue:@YES forKey:@"isHDUpload"]; } @catch (__unused NSException *exception) {} } if (TTOrigUpload) ((void (*)(id, SEL))TTOrigUpload)(self, _cmd); }
static IMP TTOrigWarning;
static BOOL TTHookWarning(id self, SEL _cmd) { if (TTBool(@"disableWarnings")) return NO; return TTOrigWarning ? ((BOOL (*)(id, SEL))TTOrigWarning)(self, _cmd) : NO; }
static IMP TTOrigTrack;
static void TTHookTrack(id self, SEL _cmd) { if (!TTBool(@"anonymousProfiles") && TTOrigTrack) ((void (*)(id, SEL))TTOrigTrack)(self, _cmd); }
static IMP TTOrigCommentLike;
static void TTHookCommentLike(id self, SEL _cmd, id comment) { if (TTOrigCommentLike) ((void (*)(id, SEL, id))TTOrigCommentLike)(self, _cmd, comment); }
static IMP TTOrigOpenURL;
static void TTHookOpenURL(id self, SEL _cmd, NSURL *url, NSDictionary *options, void (^completion)(BOOL)) { if (TTOrigOpenURL) ((void (*)(id, SEL, NSURL *, NSDictionary *, void (^)(BOOL)))TTOrigOpenURL)(self, _cmd, url, options, completion); }

void TTInstallRuntimeHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TTInstallHook("AWEFeedContainerViewController", @selector(viewDidAppear:), (IMP)TTHookFeedAppear, &TTOrigFeedAppear, "feed.viewDidAppear");
        TTInstallHook("AWEFeedContainerViewController", @selector(refresh), (IMP)TTHookFeedRefresh, &TTOrigFeedRefresh, "feed.refresh");
        TTInstallHook("AWEFeedCellViewController", @selector(setAwemeModel:), (IMP)TTHookFeedModel, &TTOrigFeedModel, "feed.setAwemeModel");
        TTInstallHook("AWEAwemeModel", @selector(isSensitive), (IMP)TTHookSensitive, &TTOrigSensitive, "aweme.isSensitive");
        TTInstallHook("AWEVideoModel", @selector(isLoop), (IMP)TTHookLoop, &TTOrigLoop, "video.isLoop");
        TTInstallHook("AWEVideoModel", @selector(forceHD), (IMP)TTHookForceHD, &TTOrigForceHD, "video.forceHD");
        TTInstallHook("AWEStoryContainerViewController", @selector(viewDidAppear:), (IMP)TTHookStoryAppear, &TTOrigStoryAppear, "story.viewDidAppear");
        TTInstallHook("AWEIMMessageCellNode", @selector(setRead:), (IMP)TTHookMessageRead, &TTOrigMessageRead, "messages.setRead");
        TTInstallHook("AWEIMInputViewController", @selector(sendTypingIndicator:), (IMP)TTHookTyping, &TTOrigTyping, "messages.typing");
        TTInstallHook("AWEAwemePlayVideoPlayerController", @selector(setRate:), (IMP)TTHookPlayerRate, &TTOrigPlayerRate, "player.setRate");
        TTInstallHook("AWEVideoPublishViewController", @selector(startUpload), (IMP)TTHookUpload, &TTOrigUpload, "upload.startUpload");
        TTInstallHook("AWESettingsViewModel", @selector(shouldShowWarning), (IMP)TTHookWarning, &TTOrigWarning, "settings.warning");
        TTInstallHook("AWEUserProfileViewController", @selector(trackProfileView), (IMP)TTHookTrack, &TTOrigTrack, "profile.trackProfileView");
        TTInstallHook("AWECommentListViewController", @selector(likeComment:), (IMP)TTHookCommentLike, &TTOrigCommentLike, "comments.likeComment");
        TTInstallHook("UIApplication", @selector(openURL:options:completionHandler:), (IMP)TTHookOpenURL, &TTOrigOpenURL, "application.openURL");
    });
}
