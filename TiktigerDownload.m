#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "substrate.h"
#import "TiktigerPrefs.h"

static void (*orig_storyViewDidAppear)(id, SEL, BOOL);
static void new_storyViewDidAppear(id self, SEL _cmd, BOOL animated) {
    orig_storyViewDidAppear(self, _cmd, animated);
    if (!TTBool(@"downloadStories")) return;
    UIView *view = [self valueForKey:@"view"];
    if ([view viewWithTag:3201]) return;
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.tag = 3201;
    b.frame = CGRectMake(view.bounds.size.width - 66, 50, 50, 50);
    [b setImage:[UIImage systemImageNamed:@"arrow.down.circle"] forState:UIControlStateNormal];
    b.tintColor = [UIColor whiteColor];
    [view addSubview:b];
}

static void (*orig_markAsRead)(id, SEL);
static void new_markAsRead(id self, SEL _cmd) {
    if (TTBool(@"unseenStories")) return;
    orig_markAsRead(self, _cmd);
}

__attribute__((constructor)) static void TiktigerDownloadInit(void) {
    Class storyVC = objc_getClass("AWEStoryContainerViewController");
    if (storyVC) {
        MSHookMessageEx(storyVC, @selector(viewDidAppear:), (IMP)new_storyViewDidAppear, (IMP *)&orig_storyViewDidAppear);
        MSHookMessageEx(storyVC, @selector(markAsRead), (IMP)new_markAsRead, (IMP *)&orig_markAsRead);
    }
}
