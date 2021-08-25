//
//  LSWeightData.m
//  LifesenseBle
//
//  Created by lifesense on 14-8-1.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import "LSWeightData.h"
#import "LSFormatConverter.h"

@implementation LSWeightData

-(NSString *)description
{
    NSDictionary *info=[LSFormatConverter dictionaryWithProperty:self];
    return [NSString stringWithFormat:@"%@",info];
    
}
@end
