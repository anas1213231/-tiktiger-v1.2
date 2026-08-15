#import <UIKit/UIKit.h>
#import "TiktigerPrefs.h"
%hook AWEUserProfileViewController
- (void)viewDidLoad{ %orig; if(TTBool(@"saveAvatar")||TTBool(@"copyBio")){ UILongPressGestureRecognizer *g=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(ttProfileLongPress:)]; [self.view addGestureRecognizer:g]; } if(TTBool(@"profileVideoCount")){ UILabel *badge=[[UILabel alloc]initWithFrame:CGRectMake(12,90,130,24)]; badge.tag=3301; badge.textColor=UIColor.whiteColor; badge.backgroundColor=[UIColor colorWithRed:.15 green:.55 blue:1 alpha:.9]; badge.layer.cornerRadius=8; badge.clipsToBounds=YES; badge.textAlignment=NSTextAlignmentCenter; id count=nil; @try{count=[self valueForKeyPath:@"userModel.awemeCount"]; }@catch(__unused NSException *e){} badge.text=[NSString stringWithFormat:@"%@ videos",count?:@"0"]; [self.view addSubview:badge]; } }
%new - (void)ttProfileLongPress:(UILongPressGestureRecognizer *)g{ if(g.state!=UIGestureRecognizerStateBegan)return; UIView *v=[g.view hitTest:[g locationInView:g.view] withEvent:nil]; if([v isKindOfClass:UIImageView.class]&&TTBool(@"saveAvatar")){TTSaveImage(((UIImageView *)v).image);return;} if(TTBool(@"copyBio")){id bio=nil;@try{bio=[self valueForKeyPath:@"userModel.bio"]; }@catch(__unused NSException *e){} if([bio isKindOfClass:NSString.class])UIPasteboard.generalPasteboard.string=bio;} }
- (void)trackProfileView{ if(TTBool(@"anonymousProfiles"))return; %orig; }
- (void)followUser:(id)user{ if(!TTBool(@"confirmFollow")){%orig(user);return;} TTConfirm(self,@"Follow",@"Confirm follow action",^{ %orig(user); }); }
%end
%hook AWEUserModel
- (NSString *)bio{ NSString *b=%orig; if(TTBool(@"expandedBio"))return [b substringToIndex:MIN(b.length,4096)]; return b; }
%end
- (NSInteger)followStatus{ NSInteger s=%orig; return s; }
%hook AWEUserProfileViewController
- (void)renderFollowStatus:(id)status{ if(TTBool(@"followStatus")){ self.view.accessibilityValue=[NSString stringWithFormat:@"%@",status]; } %orig(status); }
- (void)setLikeCount:(long long)count{ if(TTBool(@"profileLikes")){ self.view.accessibilityHint=[NSString stringWithFormat:@"likes:%lld",count]; } %orig(count); }
- (void)setVideoCreateTime:(long long)time{ if(TTBool(@"uploadDate")){ NSDate *date=[NSDate dateWithTimeIntervalSince1970:time]; NSString *format=TTString(@"dateFormat",@"dd.MM.yyyy"); self.view.accessibilityLabel=[[NSDateFormatter new] stringFromDate:date]; NSDateFormatter *f=[NSDateFormatter new]; f.dateFormat=format; self.view.accessibilityLabel=[f stringFromDate:date]; } %orig(time); }
%end
