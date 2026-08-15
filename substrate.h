#ifndef _SUBSTRATE_H_
#define _SUBSTRATE_H_
#import <objc/runtime.h>
#import <objc/message.h>

#ifdef __cplusplus
extern "C" {
#endif

void MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old);
void MSHookFunction(void *symbol, void *hook, void **old);

#ifdef __cplusplus
}
#endif

#endif
