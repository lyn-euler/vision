//
//  NSObject+Zombie.m
//  CoRe
//
//  Created by ello on 2022/3/16.
//

#import "NSObject+Zombie.h"
#import <objc/runtime.h>
#import "CRZombileObject.h"
#import "CRZombile.h"
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
//#import "CoRe-Swift.h"
//static char const * _CR_ZOMBIE_PREFIX = "_CR_ZOMBILE_";

static void inline _SwizzleInstanceMethod(Class cls, SEL origSelector, SEL swizzledSelector) {
    Method origMethod = class_getInstanceMethod(cls, origSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    BOOL result = class_addMethod(cls, origSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (result) {
        class_replaceMethod(cls, swizzledSelector, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }else {
        method_exchangeImplementations(origMethod, swizzledMethod);
    }
}


@implementation NSObject (Zombie)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _SwizzleInstanceMethod(self, NSSelectorFromString(@"dealloc"), @selector(zombie_dealloc));
    });
}

- (void)zombie_dealloc {
    
    if (!CRZombile.shared.zombileEnable|| CRZombile.shared.filter(self.class)) {
        [self zombie_dealloc];
        return;
    }else if (object_getClass(self) == CRZombileObject.class) {
        return;
    }
    
    const char *origClsName = object_getClassName(self);
  
    objc_destructInstance(self);
    object_setClass(self, CRZombileObject.class);
    object_setInstanceVariable(self, "origClsName", (void*)origClsName);
//    [self zombie_dealloc];
//    NSArray<NSString*> *callStackSymbols = NSThread.callStackSymbols;
}

@end

