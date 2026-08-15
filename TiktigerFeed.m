#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "TiktigerPrefs.h"

static void (*orig_feedViewDidAppear)(id, SEL, BOOL);
static void new_feedViewDidAppear(id self, SEL _cmd, BOOL animated) {
    orig_feedViewDidAppear(self, _cmd, animated);
    UIView *view = [self valueForKey:@"view"];
    if (!TTBool(@"floatingHUD")) return;
    if ([view viewWithTag:2101]) return;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.tag = 2101;
    btn.frame = CGRectMake(view.bounds.size.width - 60, 50, 44, 44);
    btn.backgroundColor = [UIColor colorWithRed:0.12 green:0.72 blue:0.28 alpha:0.96];
    btn.layer.cornerRadius = 22;
    [btn setTitle:@"TT" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:23];
    [btn addTarget:self action:@selector(tt_open:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:btn];
}

static void tt_openSettings(id self, SEL _cmd) {
    TTShowSettings((UIViewController *)self);
}

static void (*orig_playViewDidAppear)(id, SEL, BOOL);
static void new_playViewDidAppear(id self, SEL _cmd, BOOL animated) {
    orig_playViewDidAppear(self, _cmd, animated);
    UIView *view = [self valueForKey:@"view"];
    if (TTBool(@"progressBar") && ![view viewWithTag:2001]) {
        UIProgressView *p = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        p.tag = 2001;
        p.frame = CGRectMake(0, view.bounds.size.height - 2, view.bounds.size.width, 2);
        p.progressTintColor = [UIColor whiteColor];
        [view addSubview:p];
    }
    if (TTBool(@"downloadButton") && ![view viewWithTag:2002]) {
        UIButton *dl = [UIButton buttonWithType:UIButtonTypeSystem];
        dl.tag = 2002;
        dl.frame = CGRectMake(18, view.bounds.size.height - 330, 48, 48);
        dl.backgroundColor = [UIColor colorWithWhite:0 alpha:0.38];
        dl.layer.cornerRadius = 24;
        [dl setImage:[UIImage systemImageNamed:@"arrow.down.circle.fill"] forState:UIControlStateNormal];
        dl.tintColor = [UIColor whiteColor];
        [dl addTarget:self action:@selector(tt_dl:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:dl];
    }
}

static void tt_downloadVideo(id self, SEL _cmd) {
    id model = nil;
    @try { model = [self valueForKey:@"awemeModel"]; } @catch (NSException *e) {}
    TTDownloadMedia(TTExtractMediaURL(model), (UIViewController *)self, TTBool(@"showShareAfterDownload"));
}

static BOOL (*orig_isSensitive)(id, SEL);
static BOOL new_isSensitive(id self, SEL _cmd) {
    if (TTBool(@"disableSensitiveFilter")) return NO;
    return orig_isSensitive(self, _cmd);
}

static BOOL (*orig_isLoop)(id, SEL);
static BOOL new_isLoop(id self, SEL _cmd) {
    if (TTBool(@"stopReplay")) return NO;
    return orig_isLoop(self, _cmd);
}

static BOOL (*orig_forceHD)(id, SEL);
static BOOL new_forceHD(id self, SEL _cmd) {
    if (TTBool(@"highQualityUpload")) return YES;
    return orig_forceHD(self, _cmd);
}

__attribute__((constructor)) static void TiktigerFeedInit(void) {
    Class feedVC = objc_getClass("AWEFeedContainerViewController");
    if (feedVC) {
        MSHookMessageEx(feedVC, @selector(viewDidAppear:), (IMP)new_feedViewDidAppear, (IMP *)&orig_feedViewDidAppear);
        class_addMethod(feedVC, @selector(tt_open:), (IMP)tt_openSettings, "v@:@");
    }
    Class playVC = objc_getClass("AWEPlayInteractionViewController");
    if (playVC) {
        MSHookMessageEx(playVC, @selector(viewDidAppear:), (IMP)new_playViewDidAppear, (IMP *)&orig_playViewDidAppear);
        class_addMethod(playVC, @selector(tt_dl:), (IMP)tt_downloadVideo, "v@:@");
    }
    Class awemeModel = objc_getClass("AWEAwemeModel");
    if (awemeModel) {
        MSHookMessageEx(awemeModel, @selector(isSensitive), (IMP)new_isSensitive, (IMP *)&orig_isSensitive);
    }
    Class videoModel = objc_getClass("AWEVideoModel");
    if (videoModel) {
        MSHookMessageEx(videoModel, @selector(isLoop), (IMP)new_isLoop, (IMP *)&orig_isLoop);
        MSHookMessageEx(videoModel, @selector(forceHD), (IMP)new_forceHD, (IMP *)&orig_forceHD);
    }
}
