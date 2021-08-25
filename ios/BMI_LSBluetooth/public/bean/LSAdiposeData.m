//
//  LSAdiposeData.m
//  LsBluetooth-Test
//
//  Created by lifesense on 14-9-19.
//  Copyright (c) 2014年 com.lifesense.ble. All rights reserved.
//

#import "LSAdiposeData.h"
#import "LSFormatConverter.h"

@implementation LSAdiposeData

-(NSString *)description
{
    NSDictionary *info=[LSFormatConverter dictionaryWithProperty:self];
    return [NSString stringWithFormat:@"%@",info];
    
}
@end
