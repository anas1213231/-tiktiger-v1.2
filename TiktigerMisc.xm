#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>
#import "TiktigerPrefs.h"
%hook AWESettingsViewModel
- (BOOL)shouldShowWarning{ if(TTBool(@"disableWarnings"))return NO; return %orig; }
%end
- (BOOL)showContentWarning{ if(TTBool(@"disableWarnings"))return NO; return %orig; }
%hook UIApplication
- (BOOL)openURL:(NSURL *)url options:(NSDictionary *)options completionHandler:(void (^)(BOOL))handler{ if(TTBool(@"openSafari")&&url){ BOOL ok=[[UIApplication sharedApplication]openURL:url options:@{}]; if(handler)handler(ok); return ok; } return %orig(url,options,handler); }
%end
%hook AWEVideoPublishViewController
- (void)startUpload{ if(TTBool(@"highQualityUpload")){ @try{[self setValue:@YES forKey:@"forceHD"]; [self setValue:@YES forKey:@"isHDUpload"]; }@catch(__unused NSException *e){} } %orig; }
%end
%hook AWETabBarController
- (void)viewDidAppear:(BOOL)animated{ %orig; if(TTBool(@"appLock")){ NSString *pass=[[NSUserDefaults standardUserDefaults]stringForKey:@"Tiktiger.passcode"]; if(pass.length){ UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Tiktiger locked" message:@"Enter passcode" preferredStyle:UIAlertControllerStyleAlert]; [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.secureTextEntry=YES;}]; [a addAction:[UIAlertAction actionWithTitle:@"Unlock" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x){if(![a.textFields.firstObject.text isEqualToString:pass])self.view.window.hidden=YES;}]]; [self presentViewController:a animated:YES completion:nil]; } } }
%end
%hook AWEAwemePlayVideoPlayerController
- (void)setRate:(float)rate{ if(TTBool(@"persistentSpeed"))rate=TTNumber(@"playbackSpeed",1.0); %orig(rate); }
- (float)rate{ if(TTBool(@"persistentSpeed"))return TTNumber(@"playbackSpeed",1.0); return %orig; }
%end
%hook AWENormalModeTabBarGeneralButton
- (void)sendActionsForControlEvents:(UIControlEvents)events{ if(TTBool(@"liveButtonAction")&&[self.accessibilityLabel.lowercaseString containsString:@"live"]){ if(TTBool(@"liveButtonDefault")){ %orig(events); } return; } %orig(events); }
%end
%hook AWEFeedCellViewController
- (void)setTapBotEnabled:(BOOL)enabled{ if(TTBool(@"tapBot")){ enabled=YES; } %orig(enabled); }
%end
