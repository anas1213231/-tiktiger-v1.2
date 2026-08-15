#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "substrate.h"
#import "TiktigerPrefs.h"

static void (*orig_onLike)(id, SEL, id);
static void new_onLike(id self, SEL _cmd, id sender) {
    if (!TTBool(@"confirmLike")) { orig_onLike(self, _cmd, sender); return; }
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Tiktiger" message:@"Confirm like?" preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act){ orig_onLike(self, _cmd, sender); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    [(UIViewController *)self presentViewController:a animated:YES completion:nil];
}

static void (*orig_followUser)(id, SEL, id);
static void new_followUser(id self, SEL _cmd, id user) {
    if (!TTBool(@"confirmFollow")) { orig_followUser(self, _cmd, user); return; }
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Tiktiger" message:@"Confirm follow?" preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *act){ orig_followUser(self, _cmd, user); }]];
    [a addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    [(UIViewController *)self presentViewController:a animated:YES completion:nil];
}

__attribute__((constructor)) static void TiktigerConfirmInit(void) {
    Class interVC = objc_getClass("AWEPlayInteractionViewController");
    if (interVC) {
        MSHookMessageEx(interVC, @selector(onLikeButtonTapped:), (IMP)new_onLike, (IMP *)&orig_onLike);
    }
    Class profileVC = objc_getClass("AWEUserProfileViewController");
    if (profileVC) {
        MSHookMessageEx(profileVC, @selector(followUser:), (IMP)new_followUser, (IMP *)&orig_followUser);
    }
}
