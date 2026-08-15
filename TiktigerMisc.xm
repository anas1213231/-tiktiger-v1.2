#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>
@interface AWENormalModeTabBarGeneralButton : UIButton
@end
@interface AWESettingsViewModel : NSObject
@end
@interface AWEVideoPublishViewController : UIViewController
@end
@interface AWETabBarController : UIViewController
@end
@interface AWEAwemePlayVideoPlayerController : NSObject
@end
#import "TiktigerPrefs.h"
@interface UIApplication (TiktigerHookSurface)
@end
%hook AWESettingsViewModel
- (BOOL)shouldShowWarning{ if(TTBool(@"disableWarnings"))return NO; return %orig; }
- (BOOL)showContentWarning{ if(TTBool(@"disableWarnings"))return NO; return %orig; }
%end
%hook UIApplication
- (void)openURL:(NSURL *)url options:(NSDictionary *)options completionHandler:(void (^)(BOOL))handler{ %orig; }
%end
%hook AWEVideoPublishViewController
- (void)startUpload{ if(TTBool(@"highQualityUpload")){ @try{[self setValue:@YES forKey:@"forceHD"]; [self setValue:@YES forKey:@"isHDUpload"]; }@catch(__unused NSException *e){} } %orig; }
%end
%hook AWETabBarController
- (void)viewDidAppear:(BOOL)animated{ %orig; if(TTBool(@"appLock")){ NSString *pass=[[NSUserDefaults standardUserDefaults]stringForKey:@"Tiktiger.passcode"]; if(pass.length){ UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Tiktiger" message:@"Enter passcode" preferredStyle:UIAlertControllerStyleAlert]; [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.secureTextEntry=YES;}]; [a addAction:[UIAlertAction actionWithTitle:@"Unlock" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x){if(![a.textFields.firstObject.text isEqualToString:pass])self.view.window.hidden=YES;}]]; [self presentViewController:a animated:YES completion:nil]; } } }
%end
%hook AWEAwemePlayVideoPlayerController
- (void)setRate:(float)rate{ if(TTBool(@"persistentSpeed"))rate=TTNumber(@"playbackSpeed",1.0); %orig; }
- (float)rate{ if(TTBool(@"persistentSpeed"))return TTNumber(@"playbackSpeed",1.0); return %orig; }
%end
%hook AWENormalModeTabBarGeneralButton
- (void)sendActionsForControlEvents:(UIControlEvents)events{ if(TTBool(@"liveButtonAction")&&[self.accessibilityLabel.lowercaseString containsString:@"live"]) return; %orig; }
%end
