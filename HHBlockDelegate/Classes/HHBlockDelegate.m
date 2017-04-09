//
//  HHBlockDelegate.m
//  Pods
//
//  Created by 何海 on 09/04/2017.
//
//

#import "HHBlockDelegate.h"

// Block internals.
typedef NS_OPTIONS(int, HHBlockFlags) {
    HHBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    HHBlockFlagsHasSignature          = (1 << 30)
};
typedef struct _HHBlock {
    __unused Class isa;
    HHBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct _HHBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        // requires HHBlockFlagsHasCopyDisposeHelpers
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        // requires HHBlockFlagsHasSignature
        const char *signature;
        const char *layout;
    } *descriptor;
    // imported variables
} *HHBlockRef;

static NSMethodSignature *HH_blockMethodSignature(id block, NSError **error) {
    HHBlockRef layout = (__bridge void *)block;
    if (!(layout->flags & HHBlockFlagsHasSignature)) {
        return nil;
    }
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    if (layout->flags & HHBlockFlagsHasCopyDisposeHelpers) {
        desc += 2 * sizeof(void *);
    }
    if (!desc) {
        return nil;
    }
    const char *signature = (*(const char **)desc);
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

#import <objc/runtime.h>

@interface HHBlockInfo : NSObject

@property (nonatomic, copy) id block;
@property (nonatomic, strong) NSMethodSignature *blockSignature;
@property (nonatomic, strong) NSMethodSignature *methodSignature;

@end

@implementation HHBlockInfo

- (instancetype)initWithProtocol:(Protocol *)protocol selector:(SEL)selector block:(id)block
{
    if (self = [super init]) {
        struct objc_method_description method = protocol_getMethodDescription(protocol, selector, YES, YES);
        if (method.name == NULL) {
            method = protocol_getMethodDescription(protocol, selector, NO, YES);
        }
        
        if (method.name == NULL) {
            return nil;
        }
        
        _methodSignature = [NSMethodSignature signatureWithObjCTypes:method.types];
        NSError *error = nil;
        _blockSignature = HH_blockMethodSignature(block, &error);
        self.block = block;
        if (error) {
            return nil;
        }
    }
    return self;
}

@end

@interface HHBlockDelegate ()

@property (nonatomic, strong) Protocol *protocol;
@property (nonatomic, copy) NSDictionary<NSString *, HHBlockInfo *> *selectorsToBlockInfos;

@end

@implementation HHBlockDelegate

- (instancetype)initWithProtocol:(Protocol *)protocol
               selectorsToBlocks:(NSDictionary<NSString *, id> *)selectorsToBlocks
{
    if (self != [super init]) {
        return nil;
    }
    _protocol = protocol;
    NSMutableDictionary *selectorsToBlockInfos = [NSMutableDictionary dictionaryWithCapacity:selectorsToBlocks.count];
    [selectorsToBlocks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        SEL selector = NSSelectorFromString(key);
        selectorsToBlockInfos[key] = [[HHBlockInfo alloc] initWithProtocol:protocol selector:selector block:obj];
    }];
    self.selectorsToBlockInfos = selectorsToBlockInfos;
    
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return self.selectorsToBlockInfos[NSStringFromSelector(aSelector)] ? YES : NO;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return protocol_conformsToProtocol(self.protocol, aProtocol) || [super conformsToProtocol:aProtocol];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [self.selectorsToBlockInfos[NSStringFromSelector(sel)] methodSignature] ?: [super methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)originalInvocation
{
    HHBlockInfo *blockInfo = self.selectorsToBlockInfos[NSStringFromSelector(originalInvocation.selector)];
    if (blockInfo) {
        NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:blockInfo.blockSignature];
        
        NSInteger numberOfArguments = blockInfo.blockSignature.numberOfArguments;
        
        void *argBuf = NULL;
        for (NSUInteger idx = 1; idx < numberOfArguments; idx++) {
            const char *type = [originalInvocation.methodSignature getArgumentTypeAtIndex:idx + 1];
            NSUInteger argSize;
            NSGetSizeAndAlignment(type, &argSize, NULL);
            
            if (!(argBuf = reallocf(argBuf, argSize))) {
                return;
            }
            
            [originalInvocation getArgument:argBuf atIndex:idx + 1];
            [blockInvocation setArgument:argBuf atIndex:idx];
        }
        
        [blockInvocation invokeWithTarget:blockInfo.block];
        
        if (!(argBuf = reallocf(argBuf, originalInvocation.methodSignature.methodReturnLength))) {
            return;
        }
        
        [blockInvocation getReturnValue:argBuf];
        [originalInvocation setReturnValue:argBuf];
        
        if (argBuf != NULL) {
            free(argBuf);
        }
    } else {
        [originalInvocation invoke];
    }
}

@end
