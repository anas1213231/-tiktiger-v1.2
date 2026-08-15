#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "substrate.h"
#import "TiktigerPrefs.h"

static void (*orig_profileViewDidAppear)(id, SEL, BOOL);
static void new_profileViewDidAppear(id self, SEL _cmd, BOOL animated) {
    orig_profileViewDidAppear(self, _cmd, animated);
    UIView *view = [self valueForKey:@"view"];
    if (TTBool(@"videoCount") && ![view viewWithTag:4001]) {
        id user = nil;
        @try { user = [self valueForKey:@"user"]; } @catch(NSException *e){}
        NSNumber *count = nil;
        @try { count = [user valueForKey:@"videoCount"]; } @catch(NSException *e){}
        if (count) {
            UILabel *badge = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, 120, 26)];
            badge.tag = 4001;
            badge.text = [NSString stringWithFormat:@"Videos: %@", count];
            badge.font = [UIFont boldSystemFontOfSize:12];
            badge.textColor = [UIColor whiteColor];
            badge.backgroundColor = [UIColor colorWithRed:0.12 green:0.72 blue:0.82 alpha:0.9];
            badge.textAlignment = NSTextAlignmentCenter;
            badge.layer.cornerRadius = 13;
            badge.clipsToBounds = YES;
            [view addSubview:badge];
        }
    }
    if (TTBool(@"anonymousVisit")) {
        @try { [self setValue:@YES forKey:@"isAnonymous"]; } @catch(NSException *e){}
    }
}

static void (*orig_saveProfilePhoto)(id, SEL, id);
static void tt_saveProfilePhoto(id self, SEL _cmd, id gesture) {
    if (!TTBool(@"saveProfilePhoto")) return;
    id user = nil;
    @try { user = [self valueForKey:@"user"]; } @catch(NSException *e){}
    NSString *urlStr = nil;
    @try { urlStr = [user valueForKey:@"avatarURL"]; } @catch(NSException *e){}
    if (urlStr) {
        NSURL *url = [NSURL URLWithString:urlStr];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:url];
            UIImage *img = [UIImage imageWithData:data];
            if (img) UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
        });
    }
}

__attribute__((constructor)) static void TiktigerProfileInit(void) {
    Class profileVC = objc_getClass("AWEUserProfileViewController");
    if (profileVC) {
        MSHookMessageEx(profileVC, @selector(viewDidAppear:), (IMP)new_profileViewDidAppear, (IMP *)&orig_profileViewDidAppear);
        class_addMethod(profileVC, @selector(tt_savePhoto:), (IMP)tt_saveProfilePhoto, "v@:@");
    }
}
