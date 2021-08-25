//
//  LSToolsCenter.h
//  CoreDataApp
//
//  Created by lifesense on 14-7-25.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSToolsCenter : NSObject

+(BOOL)checkPropertiesEffective:(id)obj withConstraints:(NSDictionary *)propsConstraints withoutCheckingProps:(NSArray *)uncheckPropArray;

+(NSNumber *)numberFromString:(NSString *)stringValue;

+ (NSDictionary *)classPropsFor:(Class)klass object:(id)obj;

//+(NSDictionary *)dictionaryWithProperty:(id)obj;

+(NSUInteger)unsignedIntegerValueFromString:(NSString *)strValue;

+(NSString *)parsePropertyNameFor:(id)obj withName:(id)property;


@end
