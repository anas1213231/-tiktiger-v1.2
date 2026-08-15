#import <UIKit/UIKit.h>
#import "TiktigerPrefs.h"

static UIWindow *TTOverlayWindow;
static UINavigationController *TTOverlayNavigation;
static BOOL TTArabic = YES;

@interface TTSettingsController : UITableViewController
@end
@interface TTOverlayController : UIViewController
@end

@implementation TTSettingsController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = TTArabic ? @"Tiktiger v1.1" : @"Tiktiger v1.1";
    self.tableView.backgroundColor = [UIColor colorWithWhite:.055 alpha:1];
    self.tableView.separatorColor = [UIColor colorWithWhite:.18 alpha:1];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(tt_close)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:(TTArabic ? @"English" : @"عربي") style:UIBarButtonItemStylePlain target:self action:@selector(tt_language)];
}
- (void)tt_close { [TTOverlayWindow setHidden:YES]; }
- (void)tt_language { TTArabic = !TTArabic; [[NSUserDefaults standardUserDefaults] setBool:TTArabic forKey:@"Tiktiger.languageArabic"]; [self.tableView reloadData]; self.navigationItem.rightBarButtonItem.title = TTArabic ? @"English" : @"عربي"; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return TTFeatureSections().count; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return [TTFeatureSections()[section][@"rows"] count]; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return TTFeatureSections()[section][@"title"]; }
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 54; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"TiktigerSwitchCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    NSArray *row = TTFeatureSections()[indexPath.section][@"rows"][indexPath.row];
    cell.textLabel.text = TTArabic ? row[1] : row[2];
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.backgroundColor = [UIColor colorWithWhite:.09 alpha:1];
    cell.imageView.image = [UIImage systemImageNamed:row[3]];
    cell.imageView.tintColor = [UIColor colorWithRed:.18 green:.55 blue:1 alpha:1];
    UISwitch *toggle = [UISwitch new];
    toggle.onTintColor = [UIColor colorWithRed:.12 green:.78 blue:.35 alpha:1];
    toggle.on = TTBool(row[0]);
    toggle.tag = 4000 + indexPath.section * 100 + indexPath.row;
    [toggle addTarget:self action:@selector(tt_toggle:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    return cell;
}
- (void)tt_toggle:(UISwitch *)sender {
    for (NSDictionary *section in TTFeatureSections()) {
        for (NSArray *row in section[@"rows"]) {
            NSInteger expected = 4000 + [TTFeatureSections() indexOfObject:section] * 100 + [section[@"rows"] indexOfObject:row];
            if (sender.tag == expected) { TTSetBool(row[0], sender.isOn); return; }
        }
    }
}
@end

@implementation TTOverlayController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 50, 50);
    button.center = CGPointMake(UIScreen.mainScreen.bounds.size.width - 45, 115);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    button.layer.cornerRadius = 25;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor colorWithWhite:1 alpha:.25].CGColor;
    button.backgroundColor = [UIColor colorWithRed:.05 green:.78 blue:.55 alpha:.98];
    [button setTitle:@"TT" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    button.accessibilityIdentifier = @"TiktigerFloatingButton";
    [button addTarget:self action:@selector(tt_open) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(tt_pan:)];
    [button addGestureRecognizer:pan];
    [self.view addSubview:button];
    CGPoint saved = CGPointMake([[NSUserDefaults standardUserDefaults] doubleForKey:@"Tiktiger.overlayX"], [[NSUserDefaults standardUserDefaults] doubleForKey:@"Tiktiger.overlayY"]);
    if (saved.x > 25 && saved.y > 25) button.center = saved;
}
- (void)tt_open { if (!TTOverlayNavigation) { TTSettingsController *settings = [TTSettingsController new]; TTOverlayNavigation = [[UINavigationController alloc] initWithRootViewController:settings]; TTOverlayNavigation.modalPresentationStyle = UIModalPresentationPageSheet; } [self presentViewController:TTOverlayNavigation animated:YES completion:nil]; }
- (void)tt_pan:(UIPanGestureRecognizer *)pan { UIView *button = pan.view; CGPoint delta = [pan translationInView:self.view]; button.center = CGPointMake(button.center.x + delta.x, button.center.y + delta.y); [pan setTranslation:CGPointZero inView:self.view]; if (pan.state == UIGestureRecognizerStateEnded) { [[NSUserDefaults standardUserDefaults] setDouble:button.center.x forKey:@"Tiktiger.overlayX"]; [[NSUserDefaults standardUserDefaults] setDouble:button.center.y forKey:@"Tiktiger.overlayY"]; } }
@end

void TTShowSettings(UIViewController *presenter) { if (!TTOverlayWindow) { TTInstallWindowOverlay(); } [TTOverlayWindow setHidden:NO]; if (presenter && TTOverlayNavigation.presentingViewController == nil) [presenter presentViewController:TTOverlayNavigation animated:YES completion:nil]; }

void TTInstallWindowOverlay(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (TTOverlayWindow) { [TTOverlayWindow setHidden:NO]; return; }
        TTArabic = [[NSUserDefaults standardUserDefaults] objectForKey:@"Tiktiger.languageArabic"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"Tiktiger.languageArabic"] : YES;
        TTOverlayWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        TTOverlayWindow.windowLevel = UIWindowLevelAlert + 100;
        TTOverlayWindow.backgroundColor = UIColor.clearColor;
        TTOverlayWindow.rootViewController = [TTOverlayController new];
        TTOverlayWindow.hidden = NO;
    });
}
__attribute__((constructor)) static void TiktigerWindowConstructor(void) {
    TTInstallWindowOverlay();
    dispatch_async(dispatch_get_main_queue(), ^{ TTInstallRuntimeHooks(); });
}
