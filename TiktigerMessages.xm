#import <UIKit/UIKit.h>
#import "TiktigerPrefs.h"
%hook AWEIMMessageCellNode
- (void)setRead:(BOOL)read{ if(TTBool(@"unreadMessages")) read = NO; %orig; }
- (void)setMessageRead:(BOOL)read{ if(TTBool(@"unreadMessages")) read = NO; %orig; }
%end
%hook AWEIMInputViewController
- (void)sendTypingIndicator:(BOOL)typing{ if(TTBool(@"hideTyping")) return; %orig; }
- (void)sendMessage:(id)message{ %orig; if(TTBool(@"repeatMessages")){ dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.35*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ [self sendMessage:message]; }); } }
%end
%hook AWEIMConversationViewController
- (void)viewDidLoad{ %orig; if(TTBool(@"saveCommentPhotos")){ UILongPressGestureRecognizer *g=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(ttSaveMedia:)]; [self.view addGestureRecognizer:g]; } }
%new - (void)ttSaveMedia:(UILongPressGestureRecognizer *)g{ if(g.state!=UIGestureRecognizerStateBegan)return; UIView *v=[g.view hitTest:[g locationInView:g.view] withEvent:nil]; if([v isKindOfClass:UIImageView.class])TTSaveImage(((UIImageView *)v).image); }
%end
