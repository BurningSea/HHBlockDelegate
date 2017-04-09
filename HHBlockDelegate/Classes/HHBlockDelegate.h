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

#define BlockDelegate(aProtocol, selsToBlocks) (id<aProtocol>)[[HHBlockDelegate alloc] initWithProtocol:@protocol(aProtocol) selectorsToBlocks:selsToBlocks]
