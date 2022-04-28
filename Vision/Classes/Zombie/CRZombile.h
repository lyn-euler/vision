//
//  CRZombile.h
//  CoRe
//
//  Created by ello on 2022/3/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^CRZombileFilter)(Class cls);
typedef void (^CRZombileReport)(NSString *cls, NSString *seletor);

@interface CRZombile : NSObject

+ (instancetype)shared;

- (instancetype)init NS_UNAVAILABLE;

/// 是否启用
@property(nonatomic, assign) BOOL zombileEnable;


/// 排除类
@property(nonatomic, copy, null_resettable) CRZombileFilter filter;


/// 上报回调
@property(nonatomic, copy, nullable) CRZombileReport report;

//- (BOOL)isExcludeClass:(Class)cls;

@end

NS_ASSUME_NONNULL_END
