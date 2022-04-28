//
//  VmProtect.h
//  CoRe
//
//  Created by ello on 2022/4/25.
//

#ifndef VmProtect_h
#define VmProtect_h
#include <mach/vm_map.h>
#include <stdio.h>
extern vm_prot_t VMProtectAdd(void *address, vm_prot_t addPort);
extern kern_return_t VMProtectSet(void *address, vm_prot_t protection);
#endif /* VmProtect_h */
