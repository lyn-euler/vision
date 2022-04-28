//
//  IsObjcPointer.h
//  CoRe
//
//  Created by ello on 2022/4/15.
//

#ifndef IsObjcPointer_h
#define IsObjcPointer_h

#include <stdio.h>
#include <objc/runtime.h>

/**
 * Test if a pointer is a tagged pointer
 *
 * @param inPtr the pointer to check
 * @param outClass return the registered class for pointer
 * @return true if the pointer is a tagged pointer.
 */
extern bool IsObjcTaggedPointer(const void *inPtr, Class *outClass);

/**
 * Test if a pointer is an Objective-C object
 *
 * @param inPtr is the pointer to check
 * @return true if the pointer is an Objective-C object.
 */
extern bool IsObjcObject(const void *inPtr);



#endif /* IsObjcPointer_h */
