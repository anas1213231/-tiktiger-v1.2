#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "TiktigerPrefs.h"

@interface AWEFeedContainerViewController : UIViewController @end
@interface AWEPlayInteractionViewController : UIViewController @end
@interface AWEFeedCellViewController : UIViewController @end
@interface AWEAwemeModel : NSObject @end
@interface AWEVideoModel : NSObject @end
@interface AWENormalModeTabBarGeneralButton : UIButton @end

static void ttOpenSettings(id self, SEL _cmd) {
    TTShowSettings((UIViewController *)self);
}

static void ttDownloadVideo(id self, SEL _cmd) {
    id model = nil;
    @try { model = [self valueForKey:@"awemeModel"]; } @catch (NSException *e) {}
    TTDownloadMedia(TTExtractMediaURL(model), (UIViewController *)self, TTBool(@"showShareAfterDownload"));
}

%hook AWEFeedContainerViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!TTBool(@"floatingHUD")) return;
    if ([self.view viewWithTag:2101]) return;
    class_addMethod([self class], @selector(tt_open:), (IMP)ttOpenSettings, "v@:@");
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.tag = 2101;
    btn.frame = CGRectMake(self.view.bounds.size.width - 60, 50, 44, 44);
    btn.backgroundColor = [UIColor colorWithRed:0.12 green:0.72 blue:0.28 alpha:0.96];
    btn.layer.cornerRadius = 22;
    [btn setTitle:@"TT" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:23];
    [btn addTarget:self action:@selector(tt_open:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
- (void)pullToRefresh { if (TTBool(@"disableRefresh")) return; %orig; }
- (void)refresh { if (TTBool(@"disableRefresh")) return; %orig; }
- (BOOL)shouldShowRecommendedFeed { if (TTBool(@"skipRecommended")) return NO; return %orig; }
- (void)setUIHidden:(BOOL)hidden { if (TTBool(@"hideInterface")) return; %orig; }
%end

%hook AWEFeedCellViewController
- (void)viewDidLoad {
    %orig;
    if (TTBool(@"hideAds")) {
        BOOL isAd = NO;
        @try { isAd = [[self valueForKey:@"isAd"] boolValue]; } @catch (NSException *e) {}
        if (isAd) self.view.hidden = YES;
    }
}
%end

%hook AWEPlayInteractionViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (TTBool(@"progressBar") && ![self.view viewWithTag:2001]) {
        UIProgressView *p = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        p.tag = 2001;
        p.frame = CGRectMake(0, self.view.bounds.size.height - 2, self.view.bounds.size.width, 2);
        p.progressTintColor = [UIColor whiteColor];
        [self.view addSubview:p];
    }
    if (TTBool(@"downloadButton") && ![self.view viewWithTag:2002]) {
        class_addMethod([self class], @selector(tt_dl:), (IMP)ttDownloadVideo, "v@:@");
        UIButton *dl = [UIButton buttonWithType:UIButtonTypeSystem];
        dl.tag = 2002;
        dl.frame = CGRectMake(18, self.view.bounds.size.height - 330, 48, 48);
        dl.backgroundColor = [UIColor colorWithWhite:0 alpha:0.38];
        dl.layer.cornerRadius = 24;
        [dl setImage:[UIImage systemImageNamed:@"arrow.down.circle.fill"] forState:UIControlStateNormal];
        dl.tintColor = [UIColor whiteColor];
        [dl addTarget:self action:@selector(tt_dl:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:dl];
    }
}
%end

%hook AWEAwemeModel
- (BOOL)isSensitive { if (TTBool(@"disableSensitiveFilter")) return NO; return %orig; }
%end

%hook AWEVideoModel
- (BOOL)isLoop { if (TTBool(@"stopReplay")) return NO; return %orig; }
- (BOOL)forceHD { if (TTBool(@"highQualityUpload")) return YES; return %orig; }
%end

%hook AWENormalModeTabBarGeneralButton
- (void)setHidden:(BOOL)hidden { if (TTBool(@"hideLive")) return; %orig; }
%end
