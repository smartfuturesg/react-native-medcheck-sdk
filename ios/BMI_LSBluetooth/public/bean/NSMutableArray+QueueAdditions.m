//
//  NSMutableArray+QueueAdditions.m
//  LSBluetooth-Library
//
//  Created by lifesense on 15/7/9.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import "NSMutableArray+QueueAdditions.h"

@implementation NSMutableArray (QueueAdditions)

-(id)dequeue
{
    if([self count]==0)
    {
        return nil;
    }
    id headObject=[self objectAtIndex:0];
    if(headObject!=nil)
    {
        [self removeObjectAtIndex:0];
    }
    return headObject;
}


//从队列中获取第一个元素，但不删除
-(id) peekqueue
{
    if([self count]==0)
    {
        return nil;
    }
    return [self objectAtIndex:0];
}

//向队列中插入一个元素
-(void) enqueue:(id)obj
{
    if(obj!=nil)
    {
         [self addObject:obj];
    }
   
}

@end
