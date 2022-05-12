//
//  APMLaunchMonitor.m
//  CoRe
//
//  Created by ello on 2022/4/24.
//

#import "APMLaunchMonitor.h"
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach/vm_map.h>
#import "dlfcn.h"
#import "VmProtect.h"
#import <os/lock.h>

double AppLoadTime = 0;

@import CoreFoundation;


/** dyld源码
 * //extern const Initializer  inits_start  __asm("section$start$__DATA$__mod_init_func");
 * //extern const Initializer  inits_end    __asm("section$end$__DATA$__mod_init_func");
 *
 * //static void runDyldInitializers(const struct macho_header* mh, intptr_t slide, int argc, const char* argv[], const char* envp[], const char* apple[])
 * //{
 * //    for (const Initializer* p = &inits_start; p < &inits_end; ++p) {
 * //        (*p)(argc, argv, envp, apple);
 * //    }
 * //}
 *
 * //void Loader::findAndRunAllInitializers(RuntimeState& state) const
 * //{
 * //    Diagnostics                           diag;
 * //    const MachOAnalyzer*                  ma              = this->analyzer(state);
 * //    dyld3::MachOAnalyzer::VMAddrConverter vmAddrConverter = ma->makeVMAddrConverter(true);
 * //    ma->forEachInitializer(diag, vmAddrConverter, ^(uint32_t offset) {
 * //        Initializer func = (Initializer)((uint8_t*)ma + offset);
 * //        if ( state.config.log.initializers )
 * //            state.log("running initializer %p in %s\n", func, this->path());
 * //#if __has_feature(ptrauth_calls)
 * //        func = __builtin_ptrauth_sign_unauthenticated(func, ptrauth_key_asia, 0);
 * //#endif
 * //        dyld3::ScopedTimer(DBG_DYLD_TIMING_STATIC_INITIALIZER, (uint64_t)ma, (uint64_t)func, 0);
 * //        func(state.config.process.argc, state.config.process.argv, state.config.process.envp, state.config.process.apple, state.vars);
 * //    });
 * //}
 */

/// 日志开关
__attribute__((weak)) const BOOL APMLaunchMonitorLogEnable = YES;

typedef void (*Initializer)(int argc, const char *argv[], const char *envp[], const char *apple[], const void *vars);


typedef struct ModInitImage {
    size_t total;
    size_t finished;
    uintptr_t *origInitFunc;
    //    const char * imgPath;
//    const char * origFuncSymbol;
} mod_init_image_t;


// static size_t capacity = 0;
static mod_init_image_t modInitFuncHookedImage = {
    .total        = 0,
    .finished     = 0,
    .origInitFunc = NULL,
//    .imgPath = NULL,
};
// static size_t modInitFuncHookedImageCount = 0;

static os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;

static CFAbsoluteTime modInitTotalStartTime = 0;

void hookedModInitFunc(int argc, const char *argv[], const char *envp[], const char *apple[], const void *vars)
{
    os_unfair_lock_lock(&lock);
    if (APMLaunchMonitorLogEnable && modInitFuncHookedImage.finished == 0) {
        modInitTotalStartTime = CFAbsoluteTimeGetCurrent();
    }
    Initializer orig = (Initializer)modInitFuncHookedImage.origInitFunc[modInitFuncHookedImage.finished];
    dispatch_block_t origFunc = ^{
        modInitFuncHookedImage.finished += 1;
        orig(argc, argv, envp, apple, vars);
    };

    Dl_info info;
    if (APMLaunchMonitorLogEnable) {
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        origFunc();
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        dladdr((const void *)orig, &info);
        NSString *threadName = NSThread.currentThread.isMainThread ? @"main": NSThread.currentThread.name;
        NSInteger threadNum = [[NSThread.currentThread valueForKeyPath:@"private.seqNum"] integerValue];
        printf("[__mod_init_func](thread: name=%s,number=%ld),函数名(%s)耗时:%f ms\n", threadName.UTF8String, threadNum, info.dli_sname, (endTime - startTime) * 1000);
    } else {
        origFunc();
    }

    if (modInitFuncHookedImage.finished >= modInitFuncHookedImage.total) {
        free(modInitFuncHookedImage.origInitFunc);
        modInitFuncHookedImage.origInitFunc = NULL;
        modInitFuncHookedImage.finished = 0;
        if (APMLaunchMonitorLogEnable) {
            CFAbsoluteTime modInitTotalEndTime = CFAbsoluteTimeGetCurrent();
            printf("[__mod_init_func_total]{\npath:%s,\n总耗时:%f ms\n}\n", info.dli_fname, (modInitTotalEndTime - modInitTotalStartTime) * 1000);
        }
    }
//    if (        modInitFuncHookedImageCount == 0) {
//        free(modInitFuncHookedImages);
//                modInitFuncHookedImageCount = 0;
//    }
    os_unfair_lock_unlock(&lock);
}

// void testAddImageCallback(const struct mach_header* mh, intptr_t vmaddr_slide) {
//
// }

void hookCppInitilizers(Initializer hookInitFunc)
{
    os_unfair_lock_lock(&lock);
//    uint32_t imageCount = _dyld_image_count();
    Dl_info info;

    dladdr((const void *)hookInitFunc, &info);

//    const char * mainPath = NSBundle.mainBundle.bundlePath.UTF8String;

    unsigned long size = 0;
    bool needVMProt = false;
    uintptr_t *data = (uintptr_t *)getsectiondata(info.dli_fbase, "__DATA", "__mod_init_func", &size);

    if (data == NULL) {
        data = (uintptr_t *)getsectiondata(info.dli_fbase, "__DATA_CONST", "__mod_init_func", &size);
        needVMProt = true;
    }
    modInitFuncHookedImage.total = size / sizeof(uintptr_t);
    modInitFuncHookedImage.origInitFunc = malloc(size);
    for (int idx = 0; idx < size / sizeof(uintptr_t); ++idx) {
        uintptr_t original_ptr = data[idx];
        if (needVMProt) {
            vm_prot_t origPort = VMProtectAdd(&data[idx], VM_PROT_WRITE);
            if (origPort != VM_PROT_NONE) {
                modInitFuncHookedImage.origInitFunc[idx] = original_ptr;
                data[idx] = (uintptr_t)hookInitFunc;// - (uintptr_t)info.dli_fbase + (uintptr_t)info1.dli_fbase;
                VMProtectSet(&data[idx], origPort);
            }
        } else {
            modInitFuncHookedImage.origInitFunc[idx] = original_ptr;
            data[idx] = (uintptr_t)hookInitFunc;
        }
    }
    os_unfair_lock_unlock(&lock);
}

// void hookCppInitilizers(Initializer hookInitFunc) {
//    static os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
//    os_unfair_lock_lock(&lock);
//    uint32_t imageCount = _dyld_image_count();
//    Dl_info info;
//    dladdr((const void *)hookInitFunc, &info);
//    const char * mainPath = NSBundle.mainBundle.bundlePath.UTF8String;
////    const char * machoPath = info.dli_fname;
////    void * func = dlsym(RTLD_DEFAULT, "myHookedInit");
//
////    _dyld_register_func_for_add_image(testAddImageCallback);
////    intptr_t currSlide = 0;
////    intptr_t currHeader = 0;
////    for (uint32_t i = 0; i < imageCount; i ++ ){
////        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
////        const char * imagename = _dyld_get_image_name(i);
////        if (strcmp(imagename, currFrameworkPath) == 0) {
////            currSlide = slide;
////#ifndef __LP64__
////        const struct mach_header* header = _dyld_get_image_header(i);
////#else
////        const struct mach_header_64 * header = (struct mach_header_64 *)_dyld_get_image_header(i);
////#endif
////            currHeader = (intptr_t) header;
////            break;
////        }
////    }
//
//    for (uint32_t i = 0; i < imageCount; i ++ ){
////        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
//
// #ifndef __LP64__
//        const struct mach_header* header = _dyld_get_image_header(i);
// #else
//        const struct mach_header_64 * header = (struct mach_header_64 *)_dyld_get_image_header(i);
// #endif
//
////        if (info.dli_fbase != header) {
////            continue;
////        }
//        const char * imagename = _dyld_get_image_name(i);
//        if (imagename == NULL) {
//            continue;
//        }
//
//        if (!strstr(imagename, mainPath)) {
//            continue;
//        }
//
//        if (capacity < modInitFuncHookedImageCount + 2) {
//            capacity += 10;
//            modInitFuncHookedImages = realloc(modInitFuncHookedImages, capacity * sizeof(mod_init_image_t));
//        }
//        mod_init_image_t image = {
//            .funcCount = 0,
//            .finished = 0,
//            .origInitFunc = NULL,
//            .imgPath = imagename,
////            .origFuncSymbol = NULL
//        };
//        size_t index = modInitFuncHookedImageCount ++;
//
//        unsigned long size = 0;
//        bool needVMProt = false;
//        uintptr_t * data = (uintptr_t *)getsectiondata(header, "__DATA", "__mod_init_func", &size);
//        if (data == NULL) {
//            data = (uintptr_t *)getsectiondata(header, "__DATA_CONST", "__mod_init_func", &size);
//            needVMProt = true;
//        }
//
//        image.funcCount = size/sizeof(uintptr_t);
//        image.origInitFunc = malloc(size);
//        for(int idx = 0; idx < size/sizeof(uintptr_t); ++idx){
//            uintptr_t original_ptr = data[idx];
//            if (needVMProt) {
//                vm_prot_t origPort = VMProtectAdd(&data[idx], VM_PROT_WRITE);
//                if (origPort != VM_PROT_NONE) {
//                    image.origInitFunc[idx] = original_ptr;
//                    data[idx] = (uintptr_t)hookedModInitFunc;// + currHeader - (uintptr_t)header;
//                    VMProtectSet(&data[idx], origPort);
//                }
//            }else {
//                image.origInitFunc[idx] = original_ptr;
//                data[idx] = (uintptr_t)hookInitFunc;
//            }
//        }
//        modInitFuncHookedImages[index] = image;
//    }
//
//    os_unfair_lock_unlock(&lock);
// }

// __attribute__((constructor(101))) static void test()
// {
//    printf("Visioin::::1111111111\n");
// }
//
// __attribute__((constructor(101))) static void testxxx()
// {
//    printf("Visioin::::222222222\n");
// }


@implementation APMLaunchMonitor

+ (void)load {
#ifdef DEBUG
    printf("%s\n", __func__);
#endif
    AppLoadTime = CFAbsoluteTimeGetCurrent() * 1000;
    hookCppInitilizers(hookedModInitFunc);
}

@end
