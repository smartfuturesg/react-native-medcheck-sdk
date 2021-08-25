//
//  CXDebug.m
//  ExampleApp
//
//  Created by lifesense on 14-6-20.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import "BleDebugLogger.h"

@interface BleDebugLogger()


@end

@implementation BleDebugLogger

static NSString *PERMISSIONS;

-(instancetype)init
{
   
    self=[super init];
    if(self)
    {
        PERMISSIONS=@"test";
    }
   return self;
    
}

+(void)object:(id) obj printMessage:(NSString *)message withDebugLevel:(DebugLevel)debugLevel
{
    if([PERMISSIONS isEqualToString:@"sky"])
    {
         NSLog(@"message = %@",message);
    }
    else
    {
        if(debugLevel==DEBUG_LEVEL_GENERAL)
        {
             NSLog(@"message = %@",message);
        }
    }
}

+(void)printlnMessage:(NSString *)message
{
    NSLog(@"mag - %@ ",message);

}

+(void)setDebugMode:(BOOL)enable
{
    if (enable)
    {
        PERMISSIONS=@"sky";
    }
}

+(NSString *)className:(id)obj
{
    return NSStringFromClass([obj class]);
}
@end
