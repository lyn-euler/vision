//
//  APMLaunchMonitor.h
//  CoRe
//
//  Created by ello on 2022/4/24.
//

#import <Foundation/Foundation.h>

extern const BOOL APMLaunchMonitorLogEnable;
// 启动时间ms
extern double AppLoadTime;
extern void hookedModInitFunc(int argc, const char* argv[], const char* envp[], const char* apple[], const void * vars);
typedef void (*OriginalInitializer)(int argc, const char* argv[], const char* envp[], const char* apple[], const void * vars);
extern void hookCppInitilizers(OriginalInitializer hookInitFunc);
//extern void hookCppInitilizers(void);
NS_ASSUME_NONNULL_BEGIN

@interface APMLaunchMonitor : NSObject

@end

NS_ASSUME_NONNULL_END
