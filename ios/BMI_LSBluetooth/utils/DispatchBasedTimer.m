//
//  DispatchBasedTimer.m
//  LSBluetooth-Library
//
//  Created by caichixiang on 15/10/16.
//  Copyright © 2015年 Lifesense. All rights reserved.
//

#import "DispatchBasedTimer.h"

@interface DispatchBasedTimer()

@property (nonatomic) BOOL canceled;

@end

@implementation DispatchBasedTimer


+(instancetype)timerWithDispatchQueue:(dispatch_queue_t)dispatchQueue
                timeoutInMilliSeconds:(NSUInteger)milliseconds
                             andBlock:(BTimeoutBlock)timeoutBlock
{
    return [[self alloc] initWithDispatchQueue:dispatchQueue
                         timeoutInMilliSeconds:milliseconds
                                      andBlock:timeoutBlock];
}

-(instancetype)initWithDispatchQueue:(dispatch_queue_t)dispatchQueue
               timeoutInMilliSeconds:(NSUInteger)milliseconds
                            andBlock:(BTimeoutBlock)timeoutBlock
{
    self = [super init];
    
    if (self)
    {
        _canceled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * milliseconds), dispatchQueue, ^{
            if (!self.canceled)
            {
                timeoutBlock();
            }
        });
    }
    
    return self;
}

-(void)dealloc
{
    self.canceled = YES;
}

-(void)cancel
{
    self.canceled = YES;
}



@end
