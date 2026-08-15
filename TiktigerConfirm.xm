#import <UIKit/UIKit.h>
@interface AWEPlayInteractionViewController : UIViewController
@end
@interface AWECommentListViewController : UIViewController
@end
#import "TiktigerPrefs.h"
%hook AWEPlayInteractionViewController
- (void)onLikeButtonTapped:(id)sender{ if(!TTBool(@"confirmLike")){%orig; return;} TTConfirm((UIViewController *)self,@"Like",@"Confirm like action",^{ [(id)self onLikeButtonTapped:sender]; }); }
%end
%hook AWECommentListViewController
- (void)likeComment:(id)comment{ if(!TTBool(@"confirmCommentLike")){%orig; return;} TTConfirm((UIViewController *)self,@"Like comment",@"Confirm comment like",^{ [(id)self likeComment:comment]; }); }
- (void)unlikeComment:(id)comment{ if(!TTBool(@"confirmCommentUnlike")){%orig; return;} TTConfirm((UIViewController *)self,@"Unlike comment",@"Confirm comment unlike",^{ [(id)self unlikeComment:comment]; }); }
%end
