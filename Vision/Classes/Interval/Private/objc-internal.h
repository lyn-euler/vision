//
//  objc-internal.h
//  CoRe
//
//  Created by ello on 2022/4/15.
//

#ifndef objc_internal_h
#define objc_internal_h

#pragma mark - 来源 objc4-818.2/runtime/objc-internal.h

#if __LP64__
#define OBJC_HAVE_TAGGED_POINTERS 1
#endif

#if OBJC_HAVE_TAGGED_POINTERS

// Tagged pointer layout and usage is subject to change on different OS versions.

// Tag indexes 0..<7 have a 60-bit payload.
// Tag index 7 is reserved.
// Tag indexes 8..<264 have a 52-bit payload.
// Tag index 264 is reserved.

#if __has_feature(objc_fixed_enum)  ||  __cplusplus >= 201103L
enum objc_tag_index_t : uint16_t
#else
typedef uint16_t objc_tag_index_t;
enum
#endif
{
    // 60-bit payloads
    OBJC_TAG_NSAtom            = 0,
    OBJC_TAG_1                 = 1,
    OBJC_TAG_NSString          = 2,
    OBJC_TAG_NSNumber          = 3,
    OBJC_TAG_NSIndexPath       = 4,
    OBJC_TAG_NSManagedObjectID = 5,
    OBJC_TAG_NSDate            = 6,

    // 60-bit reserved
    OBJC_TAG_RESERVED_7        = 7,

    // 52-bit payloads
    OBJC_TAG_Photos_1          = 8,
    OBJC_TAG_Photos_2          = 9,
    OBJC_TAG_Photos_3          = 10,
    OBJC_TAG_Photos_4          = 11,
    OBJC_TAG_XPC_1             = 12,
    OBJC_TAG_XPC_2             = 13,
    OBJC_TAG_XPC_3             = 14,
    OBJC_TAG_XPC_4             = 15,
    OBJC_TAG_NSColor           = 16,
    OBJC_TAG_UIColor           = 17,
    OBJC_TAG_CGColor           = 18,
    OBJC_TAG_NSIndexSet        = 19,
    OBJC_TAG_NSMethodSignature = 20,
    OBJC_TAG_UTTypeRecord      = 21,

    // When using the split tagged pointer representation
    // (OBJC_SPLIT_TAGGED_POINTERS), this is the first tag where
    // the tag and payload are unobfuscated. All tags from here to
    // OBJC_TAG_Last52BitPayload are unobfuscated. The shared cache
    // builder is able to construct these as long as the low bit is
    // not set (i.e. even-numbered tags).
    OBJC_TAG_FirstUnobfuscatedSplitTag = 136, // 128 + 8, first ext tag with high bit set

    OBJC_TAG_Constant_CFString = 136,

    OBJC_TAG_First60BitPayload = 0,
    OBJC_TAG_Last60BitPayload  = 6,
    OBJC_TAG_First52BitPayload = 8,
    OBJC_TAG_Last52BitPayload  = 263,

    OBJC_TAG_RESERVED_264      = 264
};
#if __has_feature(objc_fixed_enum)  &&  !defined(__cplusplus)
typedef enum objc_tag_index_t objc_tag_index_t;
#endif


// Returns true if tagged pointers are enabled.
// The other functions below must not be called if tagged pointers are disabled.
static inline bool
_objc_taggedPointersEnabled(void);

// Register a class for a tagged pointer tag.
// Aborts if the tag is invalid or already in use.
OBJC_EXPORT void
_objc_registerTaggedPointerClass(objc_tag_index_t tag, Class _Nonnull cls)
    OBJC_AVAILABLE(10.9, 7.0, 9.0, 1.0, 2.0);

// Returns the registered class for the given tag.
// Returns nil if the tag is valid but has no registered class.
// Aborts if the tag is invalid.
OBJC_EXPORT Class _Nullable
_objc_getClassForTag(objc_tag_index_t tag)
    OBJC_AVAILABLE(10.9, 7.0, 9.0, 1.0, 2.0);

// Create a tagged pointer object with the given tag and payload.
// Assumes the tag is valid.
// Assumes tagged pointers are enabled.
// The payload will be silently truncated to fit.
static inline void * _Nonnull
_objc_makeTaggedPointer(objc_tag_index_t tag, uintptr_t payload);

// Return true if ptr is a tagged pointer object.
// Does not check the validity of ptr's class.
static inline bool
_objc_isTaggedPointer(const void * _Nullable ptr);

// Extract the tag value from the given tagged pointer object.
// Assumes ptr is a valid tagged pointer object.
// Does not check the validity of ptr's tag.
static inline objc_tag_index_t
_objc_getTaggedPointerTag(const void * _Nullable ptr);

// Extract the payload from the given tagged pointer object.
// Assumes ptr is a valid tagged pointer object.
// The payload value is zero-extended.
static inline uintptr_t
_objc_getTaggedPointerValue(const void * _Nullable ptr);

// Extract the payload from the given tagged pointer object.
// Assumes ptr is a valid tagged pointer object.
// The payload value is sign-extended.
static inline intptr_t
_objc_getTaggedPointerSignedValue(const void * _Nullable ptr);

// Don't use the values below. Use the declarations above.

#if __arm64__
// ARM64 uses a new tagged pointer scheme where normal tags are in
// the low bits, extended tags are in the high bits, and half of the
// extended tag space is reserved for unobfuscated payloads.
#   define OBJC_SPLIT_TAGGED_POINTERS 1
#else
#   define OBJC_SPLIT_TAGGED_POINTERS 0
#endif

#if (TARGET_OS_OSX || TARGET_OS_MACCATALYST) && __x86_64__
    // 64-bit Mac - tag bit is LSB
#   define OBJC_MSB_TAGGED_POINTERS 0
#else
    // Everything else - tag bit is MSB
#   define OBJC_MSB_TAGGED_POINTERS 1
#endif

#define _OBJC_TAG_INDEX_MASK 0x7UL

#if OBJC_SPLIT_TAGGED_POINTERS
#define _OBJC_TAG_SLOT_COUNT 8
#define _OBJC_TAG_SLOT_MASK 0x7UL
#else
// array slot includes the tag bit itself
#define _OBJC_TAG_SLOT_COUNT 16
#define _OBJC_TAG_SLOT_MASK 0xfUL
#endif

#define _OBJC_TAG_EXT_INDEX_MASK 0xff
// array slot has no extra bits
#define _OBJC_TAG_EXT_SLOT_COUNT 256
#define _OBJC_TAG_EXT_SLOT_MASK 0xff

#if OBJC_SPLIT_TAGGED_POINTERS
#   define _OBJC_TAG_MASK (1UL<<63)
#   define _OBJC_TAG_INDEX_SHIFT 0
#   define _OBJC_TAG_SLOT_SHIFT 0
#   define _OBJC_TAG_PAYLOAD_LSHIFT 1
#   define _OBJC_TAG_PAYLOAD_RSHIFT 4
#   define _OBJC_TAG_EXT_MASK (_OBJC_TAG_MASK | 0x7UL)
#   define _OBJC_TAG_NO_OBFUSCATION_MASK ((1UL<<62) | _OBJC_TAG_EXT_MASK)
#   define _OBJC_TAG_CONSTANT_POINTER_MASK \
        ~(_OBJC_TAG_EXT_MASK | ((uintptr_t)_OBJC_TAG_EXT_SLOT_MASK << _OBJC_TAG_EXT_SLOT_SHIFT))
#   define _OBJC_TAG_EXT_INDEX_SHIFT 55
#   define _OBJC_TAG_EXT_SLOT_SHIFT 55
#   define _OBJC_TAG_EXT_PAYLOAD_LSHIFT 9
#   define _OBJC_TAG_EXT_PAYLOAD_RSHIFT 12
#elif OBJC_MSB_TAGGED_POINTERS
#   define _OBJC_TAG_MASK (1UL<<63)
#   define _OBJC_TAG_INDEX_SHIFT 60
#   define _OBJC_TAG_SLOT_SHIFT 60
#   define _OBJC_TAG_PAYLOAD_LSHIFT 4
#   define _OBJC_TAG_PAYLOAD_RSHIFT 4
#   define _OBJC_TAG_EXT_MASK (0xfUL<<60)
#   define _OBJC_TAG_EXT_INDEX_SHIFT 52
#   define _OBJC_TAG_EXT_SLOT_SHIFT 52
#   define _OBJC_TAG_EXT_PAYLOAD_LSHIFT 12
#   define _OBJC_TAG_EXT_PAYLOAD_RSHIFT 12
#else
#   define _OBJC_TAG_MASK 1UL
#   define _OBJC_TAG_INDEX_SHIFT 1
#   define _OBJC_TAG_SLOT_SHIFT 0
#   define _OBJC_TAG_PAYLOAD_LSHIFT 0
#   define _OBJC_TAG_PAYLOAD_RSHIFT 4
#   define _OBJC_TAG_EXT_MASK 0xfUL
#   define _OBJC_TAG_EXT_INDEX_SHIFT 4
#   define _OBJC_TAG_EXT_SLOT_SHIFT 4
#   define _OBJC_TAG_EXT_PAYLOAD_LSHIFT 0
#   define _OBJC_TAG_EXT_PAYLOAD_RSHIFT 12
#endif

// Map of tags to obfuscated tags.
extern uintptr_t objc_debug_taggedpointer_obfuscator;

#if OBJC_SPLIT_TAGGED_POINTERS
extern uint8_t objc_debug_tag60_permutations[8];

static inline uintptr_t _objc_basicTagToObfuscatedTag(uintptr_t tag) {
    return objc_debug_tag60_permutations[tag];
}

static inline uintptr_t _objc_obfuscatedTagToBasicTag(uintptr_t tag) {
    for (unsigned i = 0; i < 7; i++)
        if (objc_debug_tag60_permutations[i] == tag)
            return i;
    return 7;
}
#endif

static inline void * _Nonnull
_objc_encodeTaggedPointer(uintptr_t ptr)
{
    uintptr_t value = (objc_debug_taggedpointer_obfuscator ^ ptr);
#if OBJC_SPLIT_TAGGED_POINTERS
    if ((value & _OBJC_TAG_NO_OBFUSCATION_MASK) == _OBJC_TAG_NO_OBFUSCATION_MASK)
        return (void *)ptr;
    uintptr_t basicTag = (value >> _OBJC_TAG_INDEX_SHIFT) & _OBJC_TAG_INDEX_MASK;
    uintptr_t permutedTag = _objc_basicTagToObfuscatedTag(basicTag);
    value &= ~(_OBJC_TAG_INDEX_MASK << _OBJC_TAG_INDEX_SHIFT);
    value |= permutedTag << _OBJC_TAG_INDEX_SHIFT;
#endif
    return (void *)value;
}

static inline uintptr_t
_objc_decodeTaggedPointer_noPermute(const void * _Nullable ptr)
{
    uintptr_t value = (uintptr_t)ptr;
#if OBJC_SPLIT_TAGGED_POINTERS
    if ((value & _OBJC_TAG_NO_OBFUSCATION_MASK) == _OBJC_TAG_NO_OBFUSCATION_MASK)
        return value;
#endif
    return value ^ objc_debug_taggedpointer_obfuscator;
}

static inline uintptr_t
_objc_decodeTaggedPointer(const void * _Nullable ptr)
{
    uintptr_t value = _objc_decodeTaggedPointer_noPermute(ptr);
#if OBJC_SPLIT_TAGGED_POINTERS
    uintptr_t basicTag = (value >> _OBJC_TAG_INDEX_SHIFT) & _OBJC_TAG_INDEX_MASK;

    value &= ~(_OBJC_TAG_INDEX_MASK << _OBJC_TAG_INDEX_SHIFT);
    value |= _objc_obfuscatedTagToBasicTag(basicTag) << _OBJC_TAG_INDEX_SHIFT;
#endif
    return value;
}

static inline bool
_objc_taggedPointersEnabled(void)
{
    extern uintptr_t objc_debug_taggedpointer_mask;
    return (objc_debug_taggedpointer_mask != 0);
}

static inline void * _Nonnull
_objc_makeTaggedPointer(objc_tag_index_t tag, uintptr_t value)
{
    // PAYLOAD_LSHIFT and PAYLOAD_RSHIFT are the payload extraction shifts.
    // They are reversed here for payload insertion.

    // ASSERT(_objc_taggedPointersEnabled());
    if (tag <= OBJC_TAG_Last60BitPayload) {
        // ASSERT(((value << _OBJC_TAG_PAYLOAD_RSHIFT) >> _OBJC_TAG_PAYLOAD_LSHIFT) == value);
        uintptr_t result =
            (_OBJC_TAG_MASK |
             ((uintptr_t)tag << _OBJC_TAG_INDEX_SHIFT) |
             ((value << _OBJC_TAG_PAYLOAD_RSHIFT) >> _OBJC_TAG_PAYLOAD_LSHIFT));
        return _objc_encodeTaggedPointer(result);
    } else {
        // ASSERT(tag >= OBJC_TAG_First52BitPayload);
        // ASSERT(tag <= OBJC_TAG_Last52BitPayload);
        // ASSERT(((value << _OBJC_TAG_EXT_PAYLOAD_RSHIFT) >> _OBJC_TAG_EXT_PAYLOAD_LSHIFT) == value);
        uintptr_t result =
            (_OBJC_TAG_EXT_MASK |
             ((uintptr_t)(tag - OBJC_TAG_First52BitPayload) << _OBJC_TAG_EXT_INDEX_SHIFT) |
             ((value << _OBJC_TAG_EXT_PAYLOAD_RSHIFT) >> _OBJC_TAG_EXT_PAYLOAD_LSHIFT));
        return _objc_encodeTaggedPointer(result);
    }
}

static inline bool
_objc_isTaggedPointer(const void * _Nullable ptr)
{
    return ((uintptr_t)ptr & _OBJC_TAG_MASK) == _OBJC_TAG_MASK;
}

static inline bool
_objc_isTaggedPointerOrNil(const void * _Nullable ptr)
{
    // this function is here so that clang can turn this into
    // a comparison with NULL when this is appropriate
    // it turns out it's not able to in many cases without this
    return !ptr || ((uintptr_t)ptr & _OBJC_TAG_MASK) == _OBJC_TAG_MASK;
}

static inline objc_tag_index_t
_objc_getTaggedPointerTag(const void * _Nullable ptr)
{
    // ASSERT(_objc_isTaggedPointer(ptr));
    uintptr_t value = _objc_decodeTaggedPointer(ptr);
    uintptr_t basicTag = (value >> _OBJC_TAG_INDEX_SHIFT) & _OBJC_TAG_INDEX_MASK;
    uintptr_t extTag =   (value >> _OBJC_TAG_EXT_INDEX_SHIFT) & _OBJC_TAG_EXT_INDEX_MASK;
    if (basicTag == _OBJC_TAG_INDEX_MASK) {
        return (objc_tag_index_t)(extTag + OBJC_TAG_First52BitPayload);
    } else {
        return (objc_tag_index_t)basicTag;
    }
}

static inline uintptr_t
_objc_getTaggedPointerValue(const void * _Nullable ptr)
{
    // ASSERT(_objc_isTaggedPointer(ptr));
    uintptr_t value = _objc_decodeTaggedPointer_noPermute(ptr);
    uintptr_t basicTag = (value >> _OBJC_TAG_INDEX_SHIFT) & _OBJC_TAG_INDEX_MASK;
    if (basicTag == _OBJC_TAG_INDEX_MASK) {
        return (value << _OBJC_TAG_EXT_PAYLOAD_LSHIFT) >> _OBJC_TAG_EXT_PAYLOAD_RSHIFT;
    } else {
        return (value << _OBJC_TAG_PAYLOAD_LSHIFT) >> _OBJC_TAG_PAYLOAD_RSHIFT;
    }
}

static inline intptr_t
_objc_getTaggedPointerSignedValue(const void * _Nullable ptr)
{
    // ASSERT(_objc_isTaggedPointer(ptr));
    uintptr_t value = _objc_decodeTaggedPointer_noPermute(ptr);
    uintptr_t basicTag = (value >> _OBJC_TAG_INDEX_SHIFT) & _OBJC_TAG_INDEX_MASK;
    if (basicTag == _OBJC_TAG_INDEX_MASK) {
        return ((intptr_t)value << _OBJC_TAG_EXT_PAYLOAD_LSHIFT) >> _OBJC_TAG_EXT_PAYLOAD_RSHIFT;
    } else {
        return ((intptr_t)value << _OBJC_TAG_PAYLOAD_LSHIFT) >> _OBJC_TAG_PAYLOAD_RSHIFT;
    }
}

#   if OBJC_SPLIT_TAGGED_POINTERS
static inline void * _Nullable
_objc_getTaggedPointerRawPointerValue(const void * _Nullable ptr) {
    return (void *)((uintptr_t)ptr & _OBJC_TAG_CONSTANT_POINTER_MASK);
}
#   endif

// OBJC_HAVE_TAGGED_POINTERS
#endif


#endif /* objc_internal_h */
