#import <Foundation/Foundation.h>
#import "TiktigerPrefs.h"

void TTInstallRuntimeHooks(void) { NSLog(@"[Tiktiger] runtime hooks disabled: stability mode"); }
__attribute__((constructor)) static void TiktigerHooksConstructor(void) { /* Stability mode: intentionally no hooks. */ }
