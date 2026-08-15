#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
@interface AWECommentListViewController : UIViewController
@end
@interface AWEPhotoDetailViewController : UIViewController
@end
@interface AVCaptureSession : NSObject
@end
@interface AVCaptureVideoDataOutput : NSObject
@end
@interface AVAudioSession : NSObject
@end
#import "TiktigerPrefs.h"
%hook AWEPhotoDetailViewController
- (void)viewDidAppear:(BOOL)animated{ %orig; if(TTBool(@"photosToVideo")&&! [self.view viewWithTag:3601]){ UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; b.tag=3601; b.frame=CGRectMake(self.view.bounds.size.width-70,self.view.bounds.size.height-150,54,54); b.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin; [b setImage:[UIImage systemImageNamed:@"film"] forState:UIControlStateNormal]; [b addTarget:self action:@selector(ttExportSlideshow:) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:b]; } }
%new - (void)ttExportSlideshow:(id)sender{ NSTimeInterval slideDuration=TTNumber(@"slideDuration",3.0); [[NSUserDefaults standardUserDefaults]setDouble:slideDuration forKey:@"Tiktiger.activeSlideDuration"]; id url=nil; @try{url=[self valueForKey:@"videoURL"]; }@catch(__unused NSException *e){} TTDownloadMedia(TTExtractMediaURL(url),self,YES); }
%end
%hook AVCaptureSession
- (void)startRunning{ if(TTBool(@"fakeCamera")){ [[NSNotificationCenter defaultCenter]postNotificationName:@"TiktigerFakeCameraRequested" object:self]; } %orig; }
%end
%hook AVCaptureVideoDataOutput
- (void)setSampleBufferDelegate:(id)delegate queue:(dispatch_queue_t)queue{ if(TTBool(@"frameInjector")){ [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"Tiktiger.frameInjectorActive"]; } %orig(delegate,queue); }
%end
%hook AVAudioSession
- (BOOL)setActive:(BOOL)active error:(NSError **)error{ if(TTBool(@"fakeMicrophone")){ [[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"Tiktiger.microphoneInjectionActive"]; } return %orig(active,error); }
%end
%hook AWECommentListViewController
- (void)viewDidLoad{ %orig; if(TTBool(@"saveCommentPhotos")){ UILongPressGestureRecognizer *g=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(ttSaveCommentMedia:)]; [self.view addGestureRecognizer:g]; } }
%new - (void)ttSaveCommentMedia:(UILongPressGestureRecognizer *)g{ if(g.state!=UIGestureRecognizerStateBegan)return; UIView *v=[g.view hitTest:[g locationInView:g.view] withEvent:nil]; if([v isKindOfClass:UIImageView.class])TTSaveImage(((UIImageView *)v).image); }
%end
