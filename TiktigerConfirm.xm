#import <UIKit/UIKit.h>
@interface AWEPlayInteractionViewController : UIViewController
@end
@interface AWECommentListViewController : UIViewController
@end
#import "TiktigerPrefs.h"
%hook AWEPlayInteractionViewController
- (void)onLikeButtonTapped:(id)sender{ if(!TTBool(@"confirmLike")){%orig; return;} TTConfirm(self,@"Like",@"Confirm like action",^{ %orig(sender); }); }
%end
%hook AWECommentListViewController
- (void)likeComment:(id)comment{ if(!TTBool(@"confirmCommentLike")){%orig; return;} TTConfirm(self,@"Like comment",@"Confirm comment like",^{ %orig(comment); }); }
- (void)unlikeComment:(id)comment{ if(!TTBool(@"confirmCommentUnlike")){%orig; return;} TTConfirm(self,@"Unlike comment",@"Confirm comment unlike",^{ %orig(comment); }); }
%end
