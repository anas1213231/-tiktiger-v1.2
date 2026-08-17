#import <UIKit/UIKit.h>
#import "TiktigerPrefs.h"
#import "TiktigerResources.h"

static UIWindow *TTOverlayWindow;
static UINavigationController *TTSettingsNavigation;
static BOOL TTArabic = YES;
static UIColor *TTBackground(void) { return [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1]; }
static UIColor *TTCellBackground(void) { return [UIColor colorWithRed:0.17 green:0.17 blue:0.18 alpha:1]; }
static UIColor *TTCyan(void) { return [UIColor colorWithRed:0 green:.737 blue:.831 alpha:1]; }
static UIColor *TTBlue(void) { return [UIColor colorWithRed:.18 green:.58 blue:1 alpha:1]; }
static UIColor *TTGreen(void) { return [UIColor colorWithRed:.18 green:.82 blue:.42 alpha:1]; }
static NSArray *TTDisplaySections(void) {
    NSArray *source = TTFeatureSections();
    if (source.count < 8) return source;
    NSArray *storyRows = source[2][@"rows"];
    NSArray *mediaRows = source[3][@"rows"];
    NSArray *otherRows = [source[6][@"rows"] arrayByAddingObjectsFromArray:source[7][@"rows"]];
    return @[source[0], source[1],
             @{@"title": @"STORIES", @"rows": [storyRows subarrayWithRange:NSMakeRange(0, MIN(2, storyRows.count))]},
             @{@"title": @"MESSAGES", @"rows": storyRows.count > 2 ? [storyRows subarrayWithRange:NSMakeRange(2, storyRows.count - 2)] : @[]},
             @{@"title": @"PHOTOS", @"rows": mediaRows}, source[4], source[5],
             @{@"title": @"OTHER", @"rows": otherRows}];
}

@interface TTFeatureCell : UITableViewCell
@end
@implementation TTFeatureCell
- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundColor = UIColor.clearColor;
    self.contentView.frame = CGRectInset(self.bounds, 12, 2);
    self.contentView.backgroundColor = TTCellBackground();
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.masksToBounds = YES;
    self.imageView.tintColor = TTBlue();
    self.textLabel.textColor = UIColor.whiteColor;
    self.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.textLabel.textAlignment = TTArabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
    self.textLabel.numberOfLines = 2;
    self.separatorInset = UIEdgeInsetsMake(0, 20, 0, 20);
}
@end

@interface TTSettingsController : UITableViewController
@end
@interface TTOverlayController : UIViewController
@end

@implementation TTSettingsController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = TTBackground();
    self.tableView.backgroundColor = TTBackground();
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 26, 0);
    self.tableView.rowHeight = 58;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = TTCyan();
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor, NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightBold]};
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark.circle.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(tt_close)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:(TTArabic ? @"English" : @"عربي") style:UIBarButtonItemStylePlain target:self action:@selector(tt_language)];
    self.tableView.tableHeaderView = [self tt_headerView];
}
- (UIView *)tt_headerView {
    CGFloat width = MAX(self.view.bounds.size.width, UIScreen.mainScreen.bounds.size.width);
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 190)];
    header.backgroundColor = TTBackground();
    UIImage *coverImage = TTDeveloperCover();
    if (coverImage) {
        UIImageView *cover = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, 116)];
        cover.image = coverImage;
        cover.contentMode = UIViewContentModeScaleAspectFill;
        cover.clipsToBounds = YES;
        cover.alpha = 0.48;
        [header addSubview:cover];
        UIView *shade = [[UIView alloc] initWithFrame:cover.bounds];
        shade.backgroundColor = [UIColor colorWithWhite:0 alpha:0.42];
        [cover addSubview:shade];
    }
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake((width - 80) / 2.0, 18, 80, 80)];
    logo.layer.cornerRadius = 12;
    logo.layer.masksToBounds = YES;
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.image = TTMainLogo();
    if (!logo.image) {
        NSString *logoPath = [[NSBundle bundleForClass:self.class] pathForResource:@"tiktiger-main" ofType:@"png"];
        if (logoPath) logo.image = [UIImage imageWithContentsOfFile:logoPath];
    }
    [header addSubview:logo];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 104, width - 32, 30)];
    title.text = @"Tiktiger v1.1";
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [header addSubview:title];
    UILabel *developer = [[UILabel alloc] initWithFrame:CGRectMake(16, 138, width - 32, 20)];
    developer.text = @"@ucorc  •  TikTok 45.3";
    developer.textAlignment = NSTextAlignmentCenter;
    developer.textColor = [UIColor colorWithWhite:.62 alpha:1];
    developer.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [header addSubview:developer];
    return header;
}
- (void)tt_close { [self dismissViewControllerAnimated:YES completion:nil]; }
- (void)tt_language { TTArabic = !TTArabic; [[NSUserDefaults standardUserDefaults] setBool:TTArabic forKey:@"Tiktiger.languageArabic"]; self.navigationItem.rightBarButtonItem.title = TTArabic ? @"English" : @"عربي"; self.tableView.tableHeaderView = [self tt_headerView]; [self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return TTDisplaySections().count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [TTDisplaySections()[section][@"rows"] count]; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *titles = TTArabic ? @[@"الصفحة الرئيسية", @"التحميلات", @"الستوري", @"الرسائل", @"الصور", @"الملف الشخصي", @"التأكيدات", @"أخرى"] : @[@"HOME", @"DOWNLOADS", @"STORIES", @"MESSAGES", @"PHOTOS", @"PROFILE", @"CONFIRMATIONS", @"OTHER"];
    return section < titles.count ? titles[section] : @"OTHER";
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 42)];
    container.backgroundColor = TTBackground();
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(22, 8, container.bounds.size.width - 44, 27)];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.textColor = TTCyan();
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    label.textAlignment = TTArabic ? NSTextAlignmentRight : NSTextAlignmentLeft;
    [container addSubview:label];
    return container;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section { return 42; }
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { return 5; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TTFeatureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TiktigerFeatureCell"];
    if (!cell) cell = [[TTFeatureCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TiktigerFeatureCell"];
    NSArray *row = TTDisplaySections()[indexPath.section][@"rows"][indexPath.row];
    cell.textLabel.text = TTArabic ? row[1] : row[2];
    cell.imageView.image = [UIImage systemImageNamed:row[3]];
    cell.imageView.tintColor = indexPath.row % 3 == 0 ? TTBlue() : (indexPath.row % 3 == 1 ? TTGreen() : [UIColor colorWithRed:1 green:.32 blue:.35 alpha:1]);
    UISwitch *toggle = [UISwitch new];
    toggle.onTintColor = TTGreen();
    toggle.tintColor = [UIColor colorWithWhite:.3 alpha:1];
    toggle.on = TTBool(row[0]);
    toggle.tag = 4000 + indexPath.section * 100 + indexPath.row;
    [toggle addTarget:self action:@selector(tt_toggle:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
- (void)tt_toggle:(UISwitch *)sender {
    NSArray *sections = TTDisplaySections();
    for (NSInteger sectionIndex = 0; sectionIndex < sections.count; sectionIndex++) {
        NSArray *rows = sections[sectionIndex][@"rows"];
        for (NSInteger rowIndex = 0; rowIndex < rows.count; rowIndex++) if (sender.tag == 4000 + sectionIndex * 100 + rowIndex) { TTSetBool(rows[rowIndex][0], sender.isOn); return; }
    }
}
@end

@implementation TTOverlayController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 52, 52);
    button.center = CGPointMake(UIScreen.mainScreen.bounds.size.width - 44, 120);
    button.layer.cornerRadius = 26;
    button.layer.borderWidth = 2;
    button.layer.borderColor = [UIColor colorWithRed:.2 green:.95 blue:.7 alpha:.8].CGColor;
    button.backgroundColor = [UIColor colorWithRed:.05 green:.72 blue:.5 alpha:1];
    button.accessibilityIdentifier = @"TiktigerFloatingButton";
    NSString *downloadPath = [[NSBundle bundleForClass:self.class] pathForResource:@"tiktiger-download" ofType:@"png"];
    UIImage *downloadImage = TTDownloadIcon();
    if (!downloadImage && downloadPath) downloadImage = [UIImage imageWithContentsOfFile:downloadPath];
    if (downloadImage) { [button setImage:downloadImage forState:UIControlStateNormal]; button.imageView.contentMode = UIViewContentModeScaleAspectFit; button.imageEdgeInsets = UIEdgeInsetsMake(7, 7, 7, 7); }
    else { [button setTitle:@"TT" forState:UIControlStateNormal]; [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold]; }
    [button addTarget:self action:@selector(tt_open) forControlEvents:UIControlEventTouchUpInside];
    [button addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(tt_pan:)]];
    [self.view addSubview:button];
    CGPoint saved = CGPointMake([[NSUserDefaults standardUserDefaults] doubleForKey:@"Tiktiger.overlayX"], [[NSUserDefaults standardUserDefaults] doubleForKey:@"Tiktiger.overlayY"]);
    if (saved.x > 26 && saved.y > 26) button.center = saved;
}
- (void)tt_open { TTSettingsController *settings = [TTSettingsController new]; TTSettingsNavigation = [[UINavigationController alloc] initWithRootViewController:settings]; TTSettingsNavigation.modalPresentationStyle = UIModalPresentationPageSheet; [self presentViewController:TTSettingsNavigation animated:YES completion:nil]; }
- (void)tt_pan:(UIPanGestureRecognizer *)pan { UIView *button = pan.view; CGPoint delta = [pan translationInView:self.view]; button.center = CGPointMake(button.center.x + delta.x, button.center.y + delta.y); [pan setTranslation:CGPointZero inView:self.view]; if (pan.state == UIGestureRecognizerStateEnded) { [[NSUserDefaults standardUserDefaults] setDouble:button.center.x forKey:@"Tiktiger.overlayX"]; [[NSUserDefaults standardUserDefaults] setDouble:button.center.y forKey:@"Tiktiger.overlayY"]; } }
@end

void TTShowSettings(UIViewController *presenter) { TTInstallWindowOverlay(); }
void TTInstallWindowOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (TTOverlayWindow) { TTOverlayWindow.hidden = NO; return; }
        TTArabic = [[NSUserDefaults standardUserDefaults] objectForKey:@"Tiktiger.languageArabic"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"Tiktiger.languageArabic"] : YES;
        TTOverlayWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        TTOverlayWindow.windowLevel = UIWindowLevelAlert + 100;
        TTOverlayWindow.backgroundColor = UIColor.clearColor;
        TTOverlayWindow.rootViewController = [TTOverlayController new];
        TTOverlayWindow.hidden = NO;
    });
}
__attribute__((constructor)) static void TiktigerWindowConstructor(void) { TTInstallWindowOverlay(); }
