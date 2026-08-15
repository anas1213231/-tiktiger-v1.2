#import <UIKit/UIKit.h>
@interface AWEUserProfileViewController : UIViewController
@end
@interface AWEUserModel : NSObject
@end
#import "TiktigerPrefs.h"
%hook AWEUserProfileViewController
- (void)viewDidLoad{ %orig; if(TTBool(@"saveAvatar")||TTBool(@"copyBio")){ UILongPressGestureRecognizer *g=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(ttProfileLongPress:)]; [self.view addGestureRecognizer:g]; } if(TTBool(@"profileVideoCount")){ UILabel *badge=[[UILabel alloc]initWithFrame:CGRectMake(12,90,130,24)]; badge.tag=3301; badge.textColor=UIColor.whiteColor; badge.backgroundColor=[UIColor colorWithRed:.15 green:.55 blue:1 alpha:.9]; badge.layer.cornerRadius=8; badge.clipsToBounds=YES; badge.textAlignment=NSTextAlignmentCenter; id count=nil; @try{count=[self valueForKeyPath:@"userModel.awemeCount"]; }@catch(__unused NSException *e){} badge.text=[NSString stringWithFormat:@"عدد الفيديوهات: %@",count?:@"0"]; badge.font=[UIFont systemFontOfSize:11 weight:UIFontWeightMedium]; [self.view addSubview:badge]; } }
%new - (void)ttProfileLongPress:(UILongPressGestureRecognizer *)g{ if(g.state!=UIGestureRecognizerStateBegan)return; UIView *v=[g.view hitTest:[g locationInView:g.view] withEvent:nil]; if([v isKindOfClass:UIImageView.class]&&TTBool(@"saveAvatar")){TTSaveImage(((UIImageView *)v).image);return;} if(TTBool(@"copyBio")){id bio=nil;@try{bio=[self valueForKeyPath:@"userModel.bio"]; }@catch(__unused NSException *e){} if([bio isKindOfClass:NSString.class])UIPasteboard.generalPasteboard.string=bio;} }
- (void)trackProfileView{ if(TTBool(@"anonymousProfiles"))return; %orig; }
- (void)followUser:(id)user{ if(!TTBool(@"confirmFollow")){%orig(user); return;} TTConfirm(self,@"Follow",@"Confirm follow action",^{ %orig(user); }); }
- (void)renderFollowStatus:(id)status{ %orig; }
- (void)setLikeCount:(long long)count{ %orig; }
- (void)setVideoCreateTime:(long long)time{ %orig; }
%end
%hook AWEUserModel
- (NSString *)bio{ NSString *b=%orig; if(TTBool(@"expandedBio")&&b.length>0) return b; return b; }
%end
