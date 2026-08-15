#import <UIKit/UIKit.h>
@interface AWEStoryContainerViewController : UIViewController
@end
#import "TiktigerPrefs.h"
%hook AWEStoryContainerViewController
- (void)viewDidAppear:(BOOL)animated{ %orig; if(TTBool(@"downloadStories")&&! [self.view viewWithTag:3201]){ UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; b.tag=3201; b.frame=CGRectMake(self.view.bounds.size.width-66,50,50,50); b.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin; [b setImage:[UIImage systemImageNamed:@"arrow.down.circle"] forState:UIControlStateNormal]; b.tintColor=UIColor.whiteColor; [b addTarget:self action:@selector(ttStoryDownload:) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:b]; } }
%new - (void)ttStoryDownload:(id)sender{ id story=nil; @try{story=[self valueForKey:@"currentStory"]; }@catch(__unused NSException *e){} TTDownloadMedia(TTExtractMediaURL(story),self,YES); }
- (void)markAsRead{ if(TTBool(@"unseenStories"))return; %orig; }
- (void)markStoryAsRead:(id)story{ if(TTBool(@"unseenStories"))return; %orig; }
%end
