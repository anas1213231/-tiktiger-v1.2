#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "TiktigerPrefs.h"
#import "TiktigerResources.h"

static UIWindow *TTOverlayWindow;
static UIViewController *TTTopViewController(void) {
    UIWindow *candidate = nil;
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (!window.hidden && window.windowLevel == UIWindowLevelNormal && window.rootViewController) {
            candidate = window;
            break;
        }
    }
    UIViewController *controller = candidate.rootViewController;
    while (controller.presentedViewController && !controller.presentedViewController.isBeingDismissed) {
        controller = controller.presentedViewController;
    }
    if (controller.navigationController.visibleViewController) {
        controller = controller.navigationController.visibleViewController;
    }
    return controller;
}

static UIColor *TTColor(NSString *hex, CGFloat alpha) {
    unsigned value = 0;
    NSScanner *scanner = [NSScanner scannerWithString:[hex stringByReplacingOccurrencesOfString:@"#" withString:@""]];
    [scanner scanHexInt:&value];
    return [UIColor colorWithRed:((value >> 16) & 0xFF) / 255.0 green:((value >> 8) & 0xFF) / 255.0 blue:(value & 0xFF) / 255.0 alpha:alpha];
}

static UIColor *TTBackground(void) { return TTColor(@"#080A11", 1); }
static UIColor *TTCard(void) { return TTColor(@"#121722", 0.98); }
static UIColor *TTPrimary(void) { return TTColor(@"#56D6C7", 1); }
static UIColor *TTMuted(void) { return TTColor(@"#8D98AA", 1); }

@interface TTSettingsController : UIViewController {
    UIScrollView *_scrollView;
    BOOL _arabic;
}
@end

@interface TTLauncherController : UIViewController
@end

@implementation TTSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];
    _arabic = TTArabicLanguage();
    self.view.backgroundColor = TTBackground();
    self.modalPresentationStyle = UIModalPresentationPageSheet;
    [self buildInterface];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _scrollView.frame = self.view.bounds;
}

- (UILabel *)labelWithText:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    label.numberOfLines = 0;
    label.adjustsFontSizeToFitWidth = NO;
    return label;
}

- (void)buildInterface {
    [_scrollView removeFromSuperview];
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.backgroundColor = TTBackground();
    _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:_scrollView];

    CGFloat width = MAX(self.view.bounds.size.width, UIScreen.mainScreen.bounds.size.width);
    CGFloat y = 0;
    UIView *hero = [[UIView alloc] initWithFrame:CGRectMake(0, y, width, 224)];
    hero.backgroundColor = TTColor(@"#101A2A", 1);
    [_scrollView addSubview:hero];

    UIImageView *cover = [[UIImageView alloc] initWithFrame:hero.bounds];
    cover.image = TTDeveloperCover();
    cover.contentMode = UIViewContentModeScaleAspectFill;
    cover.alpha = 0.22;
    cover.clipsToBounds = YES;
    [hero addSubview:cover];
    CAGradientLayer *fade = [CAGradientLayer layer];
    fade.frame = hero.bounds;
    fade.colors = @[(id)[UIColor clearColor].CGColor, (id)TTBackground().CGColor];
    fade.startPoint = CGPointMake(0.5, 0.1);
    fade.endPoint = CGPointMake(0.5, 1.0);
    [hero.layer addSublayer:fade];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(width - 62, 44, 38, 38);
    close.layer.cornerRadius = 19;
    close.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    [close setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    close.tintColor = UIColor.whiteColor;
    [close addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [hero addSubview:close];

    UIButton *language = [UIButton buttonWithType:UIButtonTypeSystem];
    language.frame = CGRectMake(22, 44, 82, 38);
    language.layer.cornerRadius = 19;
    language.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    [language setTitle:(_arabic ? @"EN" : @"عربي") forState:UIControlStateNormal];
    [language setTitleColor:TTPrimary() forState:UIControlStateNormal];
    language.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    [language addTarget:self action:@selector(toggleLanguage) forControlEvents:UIControlEventTouchUpInside];
    [hero addSubview:language];

    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(24, 102, 70, 70)];
    logo.image = TTMainLogo();
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 18;
    logo.layer.masksToBounds = YES;
    logo.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    [hero addSubview:logo];

    UILabel *brand = [self labelWithText:@"Tiktiger" size:26 weight:UIFontWeightBold color:UIColor.whiteColor];
    brand.frame = CGRectMake(110, 105, width - 140, 35);
    brand.textAlignment = _arabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
    [hero addSubview:brand];
    UILabel *version = [self labelWithText:(_arabic ? @"تحكم خصوصية مستقل • إصدار 2.0" : @"Independent privacy control • v2.0") size:13 weight:UIFontWeightMedium color:TTMuted()];
    version.frame = CGRectMake(110, 145, width - 140, 24);
    version.textAlignment = _arabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
    [hero addSubview:version];
    y += hero.bounds.size.height;

    UIView *intro = [[UIView alloc] initWithFrame:CGRectMake(20, y + 20, width - 40, 80)];
    intro.backgroundColor = [UIColor colorWithWhite:1 alpha:0.035];
    intro.layer.cornerRadius = 18;
    UILabel *eyebrow = [self labelWithText:(_arabic ? @"PRIVACY LAB" : @"PRIVACY LAB") size:11 weight:UIFontWeightBold color:TTPrimary()];
    eyebrow.frame = CGRectMake(18, 14, intro.bounds.size.width - 36, 18);
    eyebrow.textAlignment = _arabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
    [intro addSubview:eyebrow];
    UILabel *desc = [self labelWithText:(_arabic ? @"أربع مفاتيح مستقلة. لا يتم تغيير أي وحدة أخرى." : @"Four isolated switches. No other module is changed.") size:13 weight:UIFontWeightRegular color:TTMuted()];
    desc.frame = CGRectMake(18, 38, intro.bounds.size.width - 36, 24);
    desc.textAlignment = _arabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
    [intro addSubview:desc];
    [_scrollView addSubview:intro];
    y += 120;

    NSArray *features = TTPrivacyFeatureDefinitions();
    for (NSInteger index = 0; index < features.count; index++) {
        NSDictionary *feature = features[index];
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(20, y, width - 40, 86)];
        card.backgroundColor = TTCard();
        card.layer.cornerRadius = 20;
        card.layer.borderWidth = 1;
        card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.055].CGColor;
        [_scrollView addSubview:card];

        UIView *iconBox = [[UIView alloc] initWithFrame:CGRectMake(_arabic ? card.bounds.size.width - 68 : 16, 19, 48, 48)];
        iconBox.autoresizingMask = _arabic ? UIViewAutoresizingFlexibleLeftMargin : UIViewAutoresizingFlexibleRightMargin;
        iconBox.layer.cornerRadius = 16;
        iconBox.backgroundColor = TTColor(feature[@"accent"], 0.16);
        UIImageView *icon = [[UIImageView alloc] initWithFrame:iconBox.bounds];
        icon.image = [UIImage systemImageNamed:feature[@"icon"]];
        icon.tintColor = TTColor(feature[@"accent"], 1);
        icon.contentMode = UIViewContentModeCenter;
        [iconBox addSubview:icon];
        [card addSubview:iconBox];

        CGFloat left = _arabic ? 18 : 82;
        CGFloat right = _arabic ? card.bounds.size.width - 82 : card.bounds.size.width - 18;
        UILabel *title = [self labelWithText:(_arabic ? feature[@"titleAR"] : feature[@"titleEN"]) size:15 weight:UIFontWeightSemibold color:UIColor.whiteColor];
        title.frame = CGRectMake(left, 13, right - left, 25);
        title.textAlignment = _arabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
        [card addSubview:title];
        UILabel *detail = [self labelWithText:(_arabic ? feature[@"detailAR"] : feature[@"detailEN"]) size:11 weight:UIFontWeightRegular color:TTMuted()];
        detail.frame = CGRectMake(left, 40, right - left, 31);
        detail.textAlignment = _arabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
        [card addSubview:detail];

        UISwitch *toggle = [UISwitch new];
        toggle.frame = CGRectMake(_arabic ? 16 : card.bounds.size.width - 70, 27, 52, 32);
        toggle.autoresizingMask = _arabic ? UIViewAutoresizingFlexibleRightMargin : UIViewAutoresizingFlexibleLeftMargin;
        toggle.onTintColor = TTColor(feature[@"accent"], 0.92);
        toggle.on = TTBool(feature[@"key"]);
        toggle.tag = 7000 + index;
        [toggle addTarget:self action:@selector(toggleFeature:) forControlEvents:UIControlEventValueChanged];
        [card addSubview:toggle];
        y += 98;
    }

    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(20, y + 2, width - 40, 90)];
    UILabel *footerLabel = [self labelWithText:(_arabic ? @"تعمل الـ Hooks بشكل محمي: إذا لم يجد التطبيق الهدف، يتم تخطيه دون إيقاف TikTok." : @"Hooks are guarded: missing targets are skipped without stopping TikTok.") size:11 weight:UIFontWeightRegular color:TTMuted()];
    footerLabel.frame = CGRectMake(16, 12, footer.bounds.size.width - 32, 46);
    footerLabel.textAlignment = _arabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
    [footer addSubview:footerLabel];
    UILabel *developer = [self labelWithText:@"Designed for @ucorc" size:11 weight:UIFontWeightMedium color:TTPrimary()];
    developer.frame = CGRectMake(16, 58, footer.bounds.size.width - 32, 18);
    developer.textAlignment = _arabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
    [footer addSubview:developer];
    [_scrollView addSubview:footer];
    _scrollView.contentSize = CGSizeMake(width, y + 112);
}

- (void)toggleFeature:(UISwitch *)sender {
    NSArray *features = TTPrivacyFeatureDefinitions();
    NSInteger index = sender.tag - 7000;
    if (index >= 0 && index < (NSInteger)features.count) TTSetBool(features[index][@"key"], sender.isOn);
}

- (void)toggleLanguage {
    _arabic = !_arabic;
    TTSetArabicLanguage(_arabic);
    [self buildInterface];
}

- (void)closeSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end

@implementation TTLauncherController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 58, 58);
    button.center = CGPointMake(UIScreen.mainScreen.bounds.size.width - 42, 136);
    button.layer.cornerRadius = 29;
    button.layer.borderWidth = 1.5;
    button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.22].CGColor;
    button.backgroundColor = TTColor(@"#101A2A", 0.94);
    button.layer.shadowColor = TTPrimary().CGColor;
    button.layer.shadowOpacity = 0.28;
    button.layer.shadowRadius = 12;
    button.layer.shadowOffset = CGSizeZero;
    UIImage *icon = TTDownloadIcon();
    if (icon) {
        [button setImage:icon forState:UIControlStateNormal];
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        button.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    } else {
        [button setTitle:@"T" forState:UIControlStateNormal];
        [button setTitleColor:TTPrimary() forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    }
    [button addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    [button addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveButton:)]];
    [self.view addSubview:button];
}

- (void)openSettings {
    UIViewController *presenter = TTTopViewController();
    if (!presenter) return;
    TTSettingsController *settings = [TTSettingsController new];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];
    navigation.navigationBarHidden = YES;
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    [presenter presentViewController:navigation animated:YES completion:nil];
}

- (void)moveButton:(UIPanGestureRecognizer *)gesture {
    UIView *button = gesture.view;
    CGPoint delta = [gesture translationInView:self.view];
    button.center = CGPointMake(button.center.x + delta.x, button.center.y + delta.y);
    [gesture setTranslation:CGPointZero inView:self.view];
}
@end

void TTShowSettings(UIViewController *presenter) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *host = presenter ?: TTTopViewController();
        if (!host) return;
        TTSettingsController *settings = [TTSettingsController new];
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];
        navigation.navigationBarHidden = YES;
        navigation.modalPresentationStyle = UIModalPresentationPageSheet;
        [host presentViewController:navigation animated:YES completion:nil];
    });
}

void TTInstallWindowOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (TTOverlayWindow) {
            TTOverlayWindow.hidden = NO;
            return;
        }
        TTOverlayWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        TTOverlayWindow.windowLevel = UIWindowLevelAlert + 100;
        TTOverlayWindow.backgroundColor = UIColor.clearColor;
        TTOverlayWindow.rootViewController = [TTLauncherController new];
        TTOverlayWindow.hidden = NO;
    });
}

__attribute__((constructor)) static void TiktigerWindowConstructor(void) {
    TTInstallWindowOverlay();
}
