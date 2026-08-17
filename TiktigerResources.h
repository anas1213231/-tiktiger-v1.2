#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSBundle *TTResourceBundle(void) {
    NSMutableArray<NSBundle *> *bundles = [NSMutableArray array];
    Class owner = objc_getClass("TTSettingsController");
    if (owner) {
        NSBundle *classBundle = [NSBundle bundleForClass:owner];
        if (classBundle) [bundles addObject:classBundle];
    }
    if (NSBundle.mainBundle) [bundles addObject:NSBundle.mainBundle];
    NSArray<NSString *> *paths = @[
        @"/Library/Application Support/TweakInject/Tiktiger.bundle",
        @"/Library/MobileSubstrate/DynamicLibraries/Tiktiger.bundle"
    ];
    for (NSString *path in paths) {
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        if (bundle) [bundles addObject:bundle];
    }
    for (NSBundle *bundle in bundles) {
        if ([bundle pathForResource:@"tiktiger-main" ofType:@"png"] ||
            [bundle pathForResource:@"tiktiger-developer-cover" ofType:@"jpg"]) return bundle;
    }
    return bundles.firstObject;
}

static UIImage *TTAssetImage(NSString *name, NSString *extension) {
    NSBundle *bundle = TTResourceBundle();
    NSString *path = [bundle pathForResource:name ofType:extension];
    return path.length ? [UIImage imageWithContentsOfFile:path] : nil;
}

static UIImage *TTMainLogo(void) {
    return TTAssetImage(@"tiktiger-main", @"png");
}

static UIImage *TTDownloadIcon(void) {
    return TTAssetImage(@"tiktiger-download", @"png");
}

static UIImage *TTDeveloperCover(void) {
    return TTAssetImage(@"tiktiger-developer-cover", @"jpg");
}
