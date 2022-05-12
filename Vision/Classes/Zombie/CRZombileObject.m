//
//  CRZombileObject.m
//  CoRe
//
//  Created by ello on 2022/3/16.
//

#import "CRZombileObject.h"
#import "CRZombile.h"

@interface CRZombileObject ()
{
    char *origClsName;
}
@end

@implementation CRZombileObject

- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSAssert(NO, @"zombile object %s", origClsName);
    // TODO: report();
    CRZombile.shared.report([NSString stringWithUTF8String:origClsName], NSStringFromSelector(aSelector));
    return nil;
}

@end
