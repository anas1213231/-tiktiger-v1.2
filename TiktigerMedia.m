#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "substrate.h"
#import <AVFoundation/AVFoundation.h>
#import "TiktigerPrefs.h"

static id (*orig_captureOutput)(id, SEL);
static id new_captureOutput(id self, SEL _cmd) {
    if (TTBool(@"fakeCamera")) {
        NSString *path = TTString(@"fakeCameraPath", @"");
        if (path) {
            UIImage *img = [UIImage imageWithContentsOfFile:path];
            if (img) return (__bridge id)(img.CGImage);
        }
    }
    return orig_captureOutput(self, _cmd);
}

static void (*orig_saveCommentImage)(id, SEL, id);
static void tt_saveCommentImage(id self, SEL _cmd, id gesture) {
    if (!TTBool(@"saveCommentImages")) return;
    UIImageView *iv = (UIImageView *)[self valueForKey:@"imageView"];
    if (iv && iv.image) {
        UIImageWriteToSavedPhotosAlbum(iv.image, nil, nil, nil);
    }
}

__attribute__((constructor)) static void TiktigerMediaInit(void) {
    Class camVC = objc_getClass("AWECameraViewController");
    if (camVC) {
        MSHookMessageEx(camVC, @selector(captureOutput), (IMP)new_captureOutput, (IMP *)&orig_captureOutput);
    }
    Class commentImg = objc_getClass("AWECommentImageCell");
    if (commentImg) {
        class_addMethod(commentImg, @selector(tt_saveImg:), (IMP)tt_saveCommentImage, "v@:@");
    }
}
