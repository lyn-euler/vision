//
//  ModInitTeest.m
//  Vision_Example
//
//  Created by ello on 2022/4/27.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

#import "ModInitTeest.h"
@import Vision;

void myHookedInit(int argc, const char* argv[], const char* envp[], const char* apple[], const void * vars)  {
    hookedModInitFunc(argc, argv, envp, apple, vars);
}
__attribute__((constructor(101))) static void tetttt()
{
    printf("风刀霜剑风刀霜剑分开了的\n");
}

@implementation ModInitTeest

+ (void)load {
    hookCppInitilizers(myHookedInit);
    NSLog(@"%s", __func__);
}

@end
