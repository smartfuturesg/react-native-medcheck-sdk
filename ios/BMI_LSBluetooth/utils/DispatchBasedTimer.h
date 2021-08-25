//
//  DispatchBasedTimer.h
//  LSBluetooth-Library
//
//  Created by caichixiang on 15/10/16.
//  Copyright © 2015年 Lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BTimeoutBlock)(void);

@interface DispatchBasedTimer : NSObject

+(instancetype)timerWithDispatchQueue:(dispatch_queue_t)dispatchQueue
                 timeoutInMilliSeconds:(NSUInteger)milliseconds
                              andBlock:(BTimeoutBlock)timeoutBlock;

-(void)cancel;

@end
