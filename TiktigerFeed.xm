#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "TiktigerPrefs.h"

static const NSInteger TTSettingsTag = 2101;
static const NSInteger TTProgressTag = 2001;
static const NSInteger TTDownloadTag = 2002;
static const NSInteger TTMetadataTag = 2003;

static id TTFeedValue(id object, NSArray<NSString *> *paths) {
    for (NSString *path in paths) {
        @try { id value = [object valueForKeyPath:path]; if (value && value != [NSNull null]) return value; }
        @catch (__unused NSException *exception) {}
    }
    return nil;
}

static NSString *TTFeedCountryCode(id value) {
    if ([value isKindOfClass:NSString.class]) return value.uppercaseString;
    if ([value respondsToSelector:@selector(stringValue)]) return [value stringValue].uppercaseString;
    return @"";
}

static NSString *TTFeedFlag(NSString *code) {
    NSString *country = TTFeedCountryCode(code);
    if (country.length != 2) return @"🌐";
    unichar first = [country characterAtIndex:0], second = [country characterAtIndex:1];
    if (first < 'A' || first > 'Z' || second < 'A' || second > 'Z') return @"🌐";
    return [NSString stringWithFormat:@"%C%C", (unichar)(0x1F1E6 + first - 'A'), (unichar)(0x1F1E6 + second - 'A')];
}

static long long TTFeedCreateTime(id aweme) {
    id raw = TTFeedValue(aweme, @[@"createTime", @"create_time", @"video.createTime"]);
    long long value = [raw respondsToSelector:@selector(longLongValue)] ? [raw longLongValue] : 0;
    return value > 20000000000LL ? value / 1000 : value;
}

static NSString *TTFeedAge(long long createTime) {
    if (createTime <= 0) return @"";
    NSInteger minutes = MAX(0, (NSInteger)(([[NSDate date] timeIntervalSince1970] - createTime) / 60.0));
    if (minutes < 60) return [NSString stringWithFormat:@"منذ %ld د", (long)MAX(1, minutes)];
    NSInteger hours = minutes / 60;
    if (hours < 24) return [NSString stringWithFormat:@"منذ %ld س", (long)hours];
    NSInteger days = hours / 24;
    if (days < 30) return [NSString stringWithFormat:@"منذ %ld يوم", (long)days];
    NSInteger months = days / 30;
    if (months < 12) return [NSString stringWithFormat:@"منذ %ld شهر", (long)months];
    return [NSString stringWithFormat:@"منذ %ld سنة", (long)(months / 12)];
}

static void TTFeedStyle(UIView *view) {
    view.backgroundColor = [UIColor colorWithWhite:0 alpha:.42];
    view.layer.cornerRadius = 6.0;
    view.layer.masksToBounds = YES;
}

static UIVisualEffectView *TTFeedMetadataBar(CGRect frame, NSString *flag, NSString *age) {
    UIVisualEffectView *bar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    bar.frame = frame;
    bar.tag = TTMetadataTag;
    bar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    TTFeedStyle(bar);
    UILabel *flagLabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, 28, frame.size.height)];
    flagLabel.text = flag.length ? flag : @"🌐";
    flagLabel.font = [UIFont systemFontOfSize:17];
    flagLabel.textAlignment = NSTextAlignmentCenter;
    flagLabel.textColor = UIColor.whiteColor;
    flagLabel.tag = 20031;
    [bar.contentView addSubview:flagLabel];
    UILabel *ageLabel = [[UILabel alloc] initWithFrame:CGRectMake(39, 0, frame.size.width - 46, frame.size.height)];
    ageLabel.text = age;
    ageLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    ageLabel.textAlignment = NSTextAlignmentRight;
    ageLabel.textColor = UIColor.whiteColor;
    ageLabel.tag = 20032;
    [bar.contentView addSubview:ageLabel];
    return bar;
}

static void TTFeedUpdateMetadata(UIView *container, id aweme) {
    [[container viewWithTag:TTMetadataTag] removeFromSuperview];
    if (!TTBool(@"contentCountry") && !TTBool(@"uploadDate")) return;
    NSString *code = TTFeedCountryCode(TTFeedValue(aweme, @[@"region", @"countryCode", @"country_code", @"author.region", @"author.countryCode", @"author.country_code"]));
    NSString *flag = TTFeedFlag(code);
    NSString *age = TTFeedAge(TTFeedCreateTime(aweme));
    CGFloat y = MAX(0, CGRectGetHeight(container.bounds) - 180.0);
    [container addSubview:TTFeedMetadataBar(CGRectMake(16, y, 148, 28), flag, age)];
}

%hook AWEFeedContainerViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (TTBool(@"floatingHUD") && ![self.view viewWithTag:TTSettingsTag]) {
        UIButton *settings = [UIButton buttonWithType:UIButtonTypeSystem];
        settings.tag = TTSettingsTag;
        settings.frame = CGRectMake(CGRectGetWidth(self.view.bounds) - 60, 50, 44, 44);
        settings.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        settings.backgroundColor = [UIColor colorWithRed:.12 green:.72 blue:.28 alpha:.96];
        settings.layer.cornerRadius = 22;
        [settings setTitle:@"⚡" forState:UIControlStateNormal];
        settings.titleLabel.font = [UIFont systemFontOfSize:23 weight:UIFontWeightSemibold];
        [settings addTarget:self action:@selector(tt_openTiktigerSettings:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:settings];
        [UIView animateWithDuration:.38 delay:0 usingSpringWithDamping:.76 initialSpringVelocity:.35 options:0 animations:^{ settings.transform = CGAffineTransformMakeScale(1.08, 1.08); } completion:nil];
    }
}
%new - (void)tt_openTiktigerSettings:(id)sender { TTShowSettings(self); }
- (void)pullToRefresh { if (TTBool(@"disableRefresh")) return; %orig; }
- (void)refresh { if (TTBool(@"disableRefresh")) return; %orig; }
- (BOOL)shouldShowRecommendedFeed { if (TTBool(@"skipRecommended")) return NO; return %orig; }
- (void)setUIHidden:(BOOL)hidden { if (TTBool(@"hideInterface")) hidden = YES; %orig(hidden); }
%end

%hook AWEFeedCellViewController
- (void)viewDidLoad {
    %orig;
    if (TTBool(@"transparentComments")) {
        for (UIView *subview in self.view.subviews) {
            NSString *label = subview.accessibilityLabel.lowercaseString ?: @"";
            if ([subview isKindOfClass:UIVisualEffectView.class] || [label containsString:@"comment"]) { subview.backgroundColor = UIColor.clearColor; subview.alpha = .35; }
        }
    }
}
- (void)setAwemeModel:(id)model {
    %orig;
    if (TTBool(@"hideAds")) {
        BOOL isAd = NO;
        @try { isAd = [[model valueForKey:@"isAd"] boolValue] || [[model valueForKey:@"isAdvert"] boolValue]; } @catch (__unused NSException *exception) {}
        if (isAd) self.view.hidden = YES;
    }
    if (TTBool(@"showUsername")) {
        NSString *uniqueID = TTFeedValue(model, @[@"author.uniqueId", @"author.unique_id", @"user.uniqueId"]);
        if ([uniqueID isKindOfClass:NSString.class] && uniqueID.length) self.view.accessibilityLabel = [NSString stringWithFormat:@"@%@", uniqueID];
    }
    if (TTBool(@"contentCountry")) self.view.accessibilityHint = TTFeedCountryCode(TTFeedValue(model, @[@"region", @"author.region"]));
}
- (void)setCommentText:(NSString *)text { if (TTBool(@"expandedComments") && text.length > 4096) { %orig([text substringToIndex:4096]); return; } %orig(text); }
%end

%hook AWEPlayInteractionViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    id aweme = nil;
    @try { aweme = [self valueForKey:@"awemeModel"]; } @catch (__unused NSException *exception) {}
    if (TTBool(@"contentCountry") || TTBool(@"uploadDate")) TTFeedUpdateMetadata(self.view, aweme);
    if (TTBool(@"progressBar") && ![self.view viewWithTag:TTProgressTag]) {
        UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progress.tag = TTProgressTag;
        progress.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - 2, CGRectGetWidth(self.view.bounds), 2);
        progress.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        progress.progressTintColor = UIColor.whiteColor;
        progress.trackTintColor = [UIColor colorWithWhite:1 alpha:.18];
        [self.view addSubview:progress];
        AVPlayer *player = nil;
        @try { player = [self valueForKey:@"player"]; } @catch (__unused NSException *exception) {}
        if ([player respondsToSelector:@selector(addPeriodicTimeObserverForInterval:queue:usingBlock:)]) {
            [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                AVPlayerItem *item = player.currentItem;
                double duration = CMTimeGetSeconds(item.duration), current = CMTimeGetSeconds(time);
                if (duration > 0 && isfinite(duration) && isfinite(current)) progress.progress = MIN(1, MAX(0, current / duration));
            }];
        }
    }
    if (TTBool(@"downloadButton") && ![self.view viewWithTag:TTDownloadTag]) {
        UIButton *download = [UIButton buttonWithType:UIButtonTypeSystem];
        download.tag = TTDownloadTag;
        download.frame = CGRectMake(18, CGRectGetHeight(self.view.bounds) - 330, 48, 48);
        download.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        download.backgroundColor = [UIColor colorWithWhite:0 alpha:.38];
        download.layer.cornerRadius = 24;
        [download setImage:[UIImage systemImageNamed:@"arrow.down.circle.fill"] forState:UIControlStateNormal];
        download.tintColor = UIColor.whiteColor;
        [download addTarget:self action:@selector(tt_downloadCurrentVideo:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:download];
    }
}
%new - (void)tt_downloadCurrentVideo:(id)sender { id model = nil; @try { model = [self valueForKey:@"awemeModel"]; } @catch (__unused NSException *exception) {} TTDownloadMedia(TTExtractMediaURL(model), self, TTBool(@"showShareAfterDownload")); }
%end

%hook AWEAwemeModel
- (BOOL)isSensitive { if (TTBool(@"disableSensitiveFilter")) return NO; return %orig; }
- (long long)createTime { return %orig; }
%end

%hook AWEVideoModel
- (BOOL)isLoop { if (TTBool(@"stopReplay")) return NO; return %orig; }
- (BOOL)forceHD { if (TTBool(@"highQualityUpload") || TTBool(@"directHDDownload")) return YES; return %orig; }
%end

%hook AWENormalModeTabBarGeneralButton
- (void)setHidden:(BOOL)hidden { if (TTBool(@"hideLive") && [self.accessibilityLabel.lowercaseString containsString:@"live"]) hidden = YES; %orig(hidden); }
- (void)sendActionsForControlEvents:(UIControlEvents)events { if (TTBool(@"hideLive") && [self.accessibilityLabel.lowercaseString containsString:@"live"]) return; %orig(events); }
%end
