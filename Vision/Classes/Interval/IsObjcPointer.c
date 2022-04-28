//
//  IsObjcPointer.c
//  CoRe
//
//  Created by ello on 2022/4/15.
//

#include "IsObjcPointer.h"
#include "objc-internal.h"
#include <mach/mach.h>

bool IsObjcTaggedPointer(const void *inPtr, Class *outClass) {
    bool isTaggedPointer = _objc_isTaggedPointer(inPtr);
    if (outClass != NULL) {
        if (isTaggedPointer) {
            objc_tag_index_t tag = _objc_getTaggedPointerTag(inPtr);
            *outClass = _objc_getClassForTag(tag);
        }else {
            outClass = NULL;
        }
    }
    return isTaggedPointer;
}

static bool _IsReadableMemory(const void *ptr);

bool IsObjcObject(const void *inPtr) {
    if (inPtr == NULL) {
        return false;
    }
    if (IsObjcTaggedPointer(inPtr, NULL)) {
        return true;
    }
    
    // # check if the pointer is aligned
    if (((uintptr_t)inPtr) % sizeof(uintptr_t) != 0) {
        return false;
    }
    
    // # Objective-C runtime has a rule that pointers in a class_t will only have bits 0 thru 46 set
    // # so if any pointer has bits 47 thru 63 high we know that this is not a valid isa
    // https://opensource.apple.com/source/lldb/lldb-310.2.36/examples/summaries/cocoa/objc_runtime.py.auto.html
    if (((uintptr_t)inPtr & 0xFFFF800000000000) != 0) {
        return false;
    }
    
    // # check if the pointer is valid and readable
    if (!_IsReadableMemory(inPtr)) {
        return false;
    }
    Class cls = object_getClass((id)inPtr);
    return cls != NULL;
}


static vm_prot_t _vm_region_get_protection(vm_address_t address)
{
    vm_address_t addr = address;
    vm_size_t size = 0;
    vm_region_basic_info_data_64_t info = { 0 };
    mach_msg_type_number_t info_count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t vm_obj;
    vm_region_64(mach_task_self(), &addr, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &info_count, &vm_obj);
    return info.protection;
}

/**
 * 判断指针指向的内存是否可读
 *
 * @param ptr is the pointer to check
 * @return true if the pointer points to readable and valid memory.
 */
static bool _IsReadableMemory(const void *ptr) {

    // 通过vm_region_64判断是否可读
//    vm_address_t address = (vm_address_t)ptr;
//    vm_size_t size;
//    vm_region_flavor_t flavor = VM_REGION_BASIC_INFO_64;
//    vm_region_basic_info_data_t infoData;
//    mach_msg_type_number_t infoCnt = VM_REGION_BASIC_INFO_COUNT_64;
//    memory_object_name_t object_name;
//    kern_return_t result = vm_region_64(mach_task_self(), &address, &size, flavor, (vm_region_info_t)&infoData, &infoCnt, &object_name);
//
//    bool hasReadPermission = (result == KERN_SUCCESS && infoData.protection & VM_PROT_READ);
    if (!_vm_region_get_protection((vm_address_t)ptr)) {
        return false;
    }
    
    // vm_read valid
    vm_offset_t data;
    mach_msg_type_number_t dataCnt;
    kern_return_t result = vm_read(mach_task_self(), (vm_address_t)ptr, sizeof(uintptr_t), &data, &dataCnt);
    return result == KERN_SUCCESS;
}


