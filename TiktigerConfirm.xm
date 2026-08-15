#import <UIKit/UIKit.h>
#import "TiktigerPrefs.h"
%hook AWEPlayInteractionViewController
- (void)likeAction{ if(!TTBool(@"confirmLike")){%orig;return;} TTConfirm(self,@"Like",@"Confirm like action",^{ %orig; }); }
- (void)onLikeButtonTapped:(id)sender{ if(!TTBool(@"confirmLike")){%orig(sender);return;} TTConfirm(self,@"Like",@"Confirm like action",^{ %orig(sender); }); }
%end
%hook AWECommentListViewController
- (void)likeComment:(id)comment{ if(!TTBool(@"confirmCommentLike")){%orig(comment);return;} TTConfirm(self,@"Like comment",@"Confirm comment like",^{ %orig(comment); }); }
- (void)unlikeComment:(id)comment{ if(!TTBool(@"confirmCommentUnlike")){%orig(comment);return;} TTConfirm(self,@"Unlike comment",@"Confirm comment unlike",^{ %orig(comment); }); }
%end
