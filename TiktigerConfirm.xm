#import <UIKit/UIKit.h>
#import "TiktigerPrefs.h"
%hook AWEPlayInteractionViewController
- (void)onLikeButtonTapped:(id)sender{ if(!TTBool(@"confirmLike")){%orig; return;} TTConfirm(self,@"Like",@"Confirm like action",^{ [self onLikeButtonTapped:sender]; }); }
%end
%hook AWECommentListViewController
- (void)likeComment:(id)comment{ if(!TTBool(@"confirmCommentLike")){%orig; return;} TTConfirm(self,@"Like comment",@"Confirm comment like",^{ [self likeComment:comment]; }); }
- (void)unlikeComment:(id)comment{ if(!TTBool(@"confirmCommentUnlike")){%orig; return;} TTConfirm(self,@"Unlike comment",@"Confirm comment unlike",^{ [self unlikeComment:comment]; }); }
%end
