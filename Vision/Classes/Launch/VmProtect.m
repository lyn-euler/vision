//
//  VmProtect.c
//  CoRe
//
//  Created by ello on 2022/4/25.
//

#include "VmProtect.h"
vm_map_t mach_task_self(void);

kern_return_t VMProtection(void *address, vm_prot_t *protection)
{
    vm_address_t addr = (vm_address_t)address;
    vm_size_t vmsize = 0;
    mach_port_t object = 0;

#if defined(__LP64__) && __LP64__
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t infoCnt = VM_REGION_BASIC_INFO_COUNT_64;
    kern_return_t ret = vm_region_64(mach_task_self(), &addr, &vmsize, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &infoCnt, &object);
#else
//    vm_region_basic_info_data_t info;
    mach_msg_type_number_t infoCnt = VM_REGION_BASIC_INFO_COUNT;
    kern_return_t ret = vm_region(mach_task_self(), &addr, &vmsize, VM_REGION_BASIC_INFO, (vm_region_info_t)info, &infoCnt, &object);
#endif
    if (ret != KERN_SUCCESS) {
        printf("vm_region block invoke pointer failed! ret:%d, addr:%p", ret, address);
        return VM_PROT_NONE;
    }
    *protection = info.protection;
    return KERN_SUCCESS;
}

vm_prot_t VMProtectAdd(void *address, vm_prot_t port)
{
    vm_prot_t protection;

    if (VMProtection(address, &protection) != KERN_SUCCESS) {
        return VM_PROT_NONE;
    }
    if ((protection & port) == 0) {
        kern_return_t ret = vm_protect(mach_task_self(), (vm_address_t)address, sizeof(address), 0, protection | port);
        if (ret != KERN_SUCCESS) {
            printf("vm_protect block invoke pointer VM_PROT_WRITE failed! ret:%d, addr:%p", ret, address);
            return VM_PROT_NONE;
        }
    }
    return protection;
}

kern_return_t VMProtectSet(void *address, vm_prot_t protection)
{
    return vm_protect(mach_task_self(), (vm_address_t)address, sizeof(address), 0, protection);
}
