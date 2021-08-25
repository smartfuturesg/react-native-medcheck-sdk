//
//  LSToolsCenter.m
//  CoreDataApp
//
//  Created by lifesense on 14-7-25.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import "LSToolsCenter.h"
#import <objc/runtime.h>
#import "BleDebugLogger.h"


static NSArray *uncheckPropertyArrays;
static NSDictionary *propertyConstraints;
static id currentCheckObject;

@implementation LSToolsCenter

#pragma mark - class method public api
+(NSUInteger)unsignedIntegerValueFromString:(NSString *)strValue
{
    if (strValue.length==0)
    {
        return 0;
    }
    else
    {
        NSNumber *number=[NSNumber numberWithLongLong:strValue.longLongValue];
        return number.unsignedIntegerValue;
    }
}

+(NSNumber *)numberFromString:(NSString *)stringValue
{
    if(stringValue.length==0)
    {
        return 0;
    }
    else
    {
        NSNumberFormatter * numformatter = [[NSNumberFormatter alloc] init];
        [numformatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber * numberValue = [numformatter numberFromString:stringValue];
        return numberValue;
    }
}




+(NSDictionary *)dictionaryWithProperty:(id)obj
{
    if(!obj)
    {
        return nil;
    }
    else
    {
        NSMutableDictionary *propertyDictionary = [[NSMutableDictionary alloc] init];

        unsigned int numberOfProperties=0;
        objc_property_t *properties=class_copyPropertyList([obj class], &numberOfProperties);
        for(int i=0;i<numberOfProperties; i++)
        {
            objc_property_t property = properties[i];
            NSString *propertyName=[NSString stringWithUTF8String:property_getName(property)];
            id propValue=[obj valueForKey:propertyName];
            if(propValue)
            {
                [propertyDictionary setObject:propValue forKey:propertyName];
            }
            else [propertyDictionary setObject:@"null" forKey:propertyName];
        }
        
        return propertyDictionary;
    }
}

+(BOOL)checkPropertiesEffective:(id)obj withConstraints:(NSDictionary *)propsConstraints withoutCheckingProps:(NSArray *)uncheckPropArray
{
    if(obj)
    {
        BOOL isValid=YES;
        uncheckPropertyArrays=uncheckPropArray;
        propertyConstraints=propsConstraints;
        currentCheckObject=obj;
        
        unsigned int numberOfProperties=0;
        objc_property_t *properties=class_copyPropertyList([obj class], &numberOfProperties);
        for(int i=0;i<numberOfProperties; i++)
        {
            objc_property_t property = properties[i];
            NSString *propertyName=[NSString stringWithUTF8String:property_getName(property)];
            id propValue=[obj valueForKey:propertyName];
            NSString *message=[NSString stringWithFormat:@"current check property= <proName- %@ ,proValue -%@>",propertyName,propValue];
            [BleDebugLogger printlnMessage:message];
            if(propValue)
            {
                //handler propvalue if it's not nil,NSNUmber type
                if([propValue isKindOfClass:[NSNumber class]])
                {
                    
                    NSNumber *numberValue=(NSNumber *)propValue;
                    //if property value is number tyep ,check the default value
                    if([numberValue isEqualToNumber:@0])
                    {
                        if (!isConstraintsProperty(propertyName, numberValue))
                        {
                            if(!isUncheckProperty(propertyName))
                            {
                                printlnErrorMessage(obj, propertyName);
                                isValid=NO;
                                break;
                                
                            }
                        }
                    }
                    if([propertyConstraints objectForKey:propertyName])
                    {
                        
                        if (!isConstraintsProperty(propertyName, numberValue))
                        {
                            if(!isUncheckProperty(propertyName))
                            {
                                printlnErrorMessage(obj, propertyName);
                                isValid=NO;
                                break;
                            }
                        }
                    }

                
                }
                if([propValue isKindOfClass:[NSString class]])
                {
                    
                    NSString *stringValue=(NSString *)propValue;
                    if(stringValue.length==0)
                    {
                        if (!isConstraintsProperty(propertyName, stringValue))
                        {
                            if(!isUncheckProperty(propertyName))
                            {
                                printlnErrorMessage(obj, propertyName);
                                isValid=NO;
                                break;
                            }
                        }
                    }
                    if([propsConstraints objectForKey:propertyName])
                    {
                        if (!isConstraintsProperty(propertyName, stringValue))
                        {
                            if(!isUncheckProperty(propertyName))
                            {
                                printlnErrorMessage(obj, propertyName);
                                isValid=NO;
                                break;
                            }
                        }

                    }
                }
            }
            else
            {
                
                //handler propvalue if it's nil,NSString,NSArray,NSDictionary type
                if(![propsConstraints objectForKey:propertyName])
                {
                    if(!isUncheckProperty(propertyName))
                    {
                        printlnErrorMessage(obj, propertyName);
                        isValid=NO;
                        break;
                    }
                }
                else
                {
                    if (!isConstraintsProperty(propertyName, propValue))
                    {
                        if(!isUncheckProperty(propertyName))
                        {
                            printlnErrorMessage(obj, propertyName);
                            isValid=NO;
                            break;
                        }
                    }

                }
                
            }
        }

        
        return isValid;
    }
    else return NO;
}

#pragma mark - test method

+(NSString *)parsePropertyNameFor:(id)obj withName:(id)property
{
    unsigned int numIvars=0;
    NSString *key=nil;
    Ivar *ivars=class_copyIvarList([obj class], &numIvars);
    for (int i=0; i<numIvars; i++)
    {
        Ivar thisIvar =ivars[i];
        if(object_getIvar(obj, thisIvar)==property)
        {
            key=[NSString stringWithUTF8String:ivar_getName(thisIvar)];
            break;
        }
    }
    free(ivars);
    return key;
    
}

+(BOOL)checkPropertiesIsEffective:(id)obj
{
    BOOL isEffective=YES;
    unsigned int numberOfProperties=0;
    objc_property_t *properties=class_copyPropertyList([obj class], &numberOfProperties);
    for(int i=0;i<numberOfProperties; i++)
    {
        NSString *key=[NSString stringWithUTF8String:property_getName(properties[i])];
        NSString *value=[obj valueForKey:key];
        //if it's nil
        if(!value)
        {
            NSString *className=NSStringFromClass([obj class]);
            NSString *error=[NSString stringWithFormat:@"%@ property(%@) is nil",className,key];
            [BleDebugLogger object:obj printMessage:error withDebugLevel:DEBUG_LEVEL_GENERAL];
            isEffective=NO;
            break;
        }
    }
    free(properties);
    return isEffective;
}


//将对象属性转换字典
+ (NSDictionary *)classPropsFor:(Class)klass object:(id)obj
{
    if (klass == NULL) {
        return nil;
    }
    
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithUTF8String:propName];
           __unused NSString *propertyType = [NSString stringWithUTF8String:propType];
            id propertyValue=[obj objectForKey:propertyName];
            NSLog(@"property name =%@,value=%@",propertyName,propertyValue);
            /*
            if(propertyValue)
            {
                if([propertyValue isKindOfClass:[NSNumber class]])
                {
                    NSNumber *numberValue=(NSNumber *)propertyValue;
                    if([numberValue isEqualToNumber:@0])
                    {
                        break;
                    }
                   else [results setObject:propertyValue forKey:propertyName];

                }
                if([propertyValue isKindOfClass:[NSString class]])
                {
                    NSString *stringValue=(NSString *)propertyValue;
                    if(stringValue.length==0)
                    {
                        break;
                    }
                    else [results setObject:propertyValue forKey:propertyName];
                }
               
            }
           */
        }
    }
    free(properties);
    
    // returning a copy here to make sure the dictionary is immutable
    return [NSDictionary dictionaryWithDictionary:results];
}




#pragma mark - private api static const method

static const BOOL isUncheckProperty(NSString *propName)
{
    if(!uncheckPropertyArrays || !propName)
    {
        return NO;
    }
    else if([uncheckPropertyArrays containsObject:propName])
    {
        return YES;
    }
    else
    {
        printlnErrorOfConstraints(propName, nil, uncheckPropertyArrays);
        return NO;
    }
    
}
static const BOOL isConstraintsProperty(NSString *propName,id propValue)
{
    if(!propertyConstraints || !propName || !propValue)
    {
        return NO;
    }
    else
    {
        id hasConstraints=[propertyConstraints objectForKey:propName];
        if(!hasConstraints)
        {
            [BleDebugLogger printlnMessage:@"no constraints"];
            return NO;
        }
        if([hasConstraints isKindOfClass:[NSArray class]])
        {
            if([propValue isKindOfClass:[NSString class]])
            {
                NSString *stringValue=(NSString *)propValue;
                for (NSString *targetValue in hasConstraints)
                {
                    if([targetValue isEqualToString:stringValue])
                    {
                        return YES;
                    }
                }
                printlnErrorOfConstraints(propName, stringValue, hasConstraints);
                return NO;
            }
            if([propValue isKindOfClass:[NSNumber class]])
            {
                NSNumber *numberValue=(NSNumber *)propValue;
                if([hasConstraints containsObject:numberValue])
                {
                    return YES;
                }
                else
                {
                     printlnErrorOfConstraints(propName, numberValue, hasConstraints);
                    return NO;
                }
            }
            else return NO;
        }
        else return NO;
        
    }
}
static const void * printlnErrorOfConstraints(NSString *propName,id propValue,NSArray *constraintsRange)
{
    NSString *errorMsg=[NSString stringWithFormat:@"property<%@> value<%@> is not a constraints(%@)",propName,propValue,constraintsRange];
    [BleDebugLogger object:currentCheckObject printMessage:errorMsg withDebugLevel:DEBUG_LEVEL_GENERAL];
    return "";
}
static const void * printlnErrorMessage(id obj,NSString * position)
{
    NSString *className=NSStringFromClass([obj class]);
    NSString *error=[NSString stringWithFormat:@"%@ property(%@) is invalid",className,position];
    [BleDebugLogger object:obj printMessage:error withDebugLevel:DEBUG_LEVEL_GENERAL];
    return "";
}



static const char * getPropertyType(objc_property_t property)
{
    const char *attributes = property_getAttributes(property);
//    printf("attributes=%s\n", attributes);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL)
    {
        if (attribute[0] == 'T' && attribute[1] != '@')
        {
            // it's a C primitive type:
            /*
             if you want a list of what will be returned for these primitives, search online for
             "objective-c" "Property Attribute Description Examples"
             apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.
             */
            return (const char *)[[NSData dataWithBytes:(attribute + 1) length:strlen(attribute) - 1] bytes];
        }
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2)
        {
            // it's an ObjC id type:
            return "id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@')
        {
            // it's another ObjC object type:
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
        }
    }
    return "";
}



@end
