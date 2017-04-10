//
//  HHBlockDelegate.h
//  Pods
//
//  Created by 何海 on 09/04/2017.
//
//

#import <Foundation/Foundation.h>

/**
 Don't use NSProxy here, as NSProxy will forward '-respondsToSelector:' automatically
 */
@interface HHBlockDelegate : NSObject

- (instancetype)initWithProtocol:(Protocol *)protocol
               selectorsToBlocks:(NSDictionary<NSString *, id> *)selectorsToBlocks;

@end

#define BlockDelegate(aProtocol) (id<aProtocol>)HHCreateDelegate(@protocol(aProtocol))

typedef id(^HHDelegateGeneration)(NSDictionary<NSString *, id> *selectorsToBlocks);

static inline HHDelegateGeneration HHCreateDelegate(Protocol *proto) {
    return ^(NSDictionary<NSString *, id> *selectorsToBlocks){
        return [[HHBlockDelegate alloc] initWithProtocol:proto selectorsToBlocks:selectorsToBlocks];
    };
}
