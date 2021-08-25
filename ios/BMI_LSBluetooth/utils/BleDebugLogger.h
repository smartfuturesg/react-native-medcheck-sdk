//
//  CXDebug.h
//  ExampleApp
//
//  Created by lifesense on 14-6-20.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

typedef enum
{
    DEBUG_LEVEL_GENERAL=1,
    DEBUG_LEVEL_ANVANCEN=2,
    DEBUG_LEVEL_SUPREME=3,
} DebugLevel;

#import <Foundation/Foundation.h>


@interface BleDebugLogger : NSObject


+(void)object:(id) obj printMessage:(NSString*) message withDebugLevel:(DebugLevel) debugLevel;

+(void)printlnMessage:(NSString *)message;

//设置调试模式
+(void)setDebugMode:(BOOL)enable;
@end
