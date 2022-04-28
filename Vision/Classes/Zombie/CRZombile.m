//
//  CRZombile.m
//  CoRe
//
//  Created by ello on 2022/3/17.
//

#import "CRZombile.h"
@import ObjectiveC.runtime;

static inline const char * MainBundlePath()
{
    static const char * path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        path = [NSBundle mainBundle].bundlePath.UTF8String;
    });
    return path;
}

__attribute__((weak)) BOOL isZombileExclude(Class cls)
{
    return YES;
    const char *imageNameCString = class_getImageName(cls);
    if (imageNameCString != NULL && strstr(imageNameCString, MainBundlePath())) {
        return NO;
    }
    return YES;
}

@implementation CRZombile

+ (instancetype)shared {
    static CRZombile *instance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

// - (BOOL)isExcludeClass:(Class)cls {
//    if (_filter) {
//        return _filter(cls);
//    }
//    return isZombileExclude(cls);
// }


- (CRZombileFilter)filter {
    if (!_filter) {
        static CRZombileFilter _defaultFilter = ^BOOL (Class cls) {
            return isZombileExclude(cls);
        };
        return _defaultFilter;
    }
    return _filter;
}

- (CRZombileReport)report {
    if (!_report) {
        _report = ^(NSString *name, NSString *selector) {
            NSLog(@"zombile object: cls->%@, sel->%@", name, selector);
        };
    }
    return _report;
}

@end
