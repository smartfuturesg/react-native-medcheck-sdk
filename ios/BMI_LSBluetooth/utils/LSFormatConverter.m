//
//  LSFormatConverter.m
//  LifesenseBle
//
//  Created by lifesense on 14-8-2.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import "LSFormatConverter.h"
#import <CoreBluetooth/CBUUID.h>
#import "LSBleGattServicesConstants.h"
#import "BleDebugLogger.h"
#import "LSDeviceInfo.h"
#import <objc/runtime.h>

static NSDate *epoch;

@implementation LSFormatConverter

NSString *const TIME_ZONE_SHANGHAI=@"Asia/Shanghai";
NSString *const TIME_ZONE_LOSANGELES=@"America/Los_Angeles";

+(void) initialize
{
    // NSString*dateString1=@"2010-01-01 00:00:00";
    // Note we use the default timezone of the device, this is the timezone in which the user is anyway
    [super initialize];
    NSDateComponents *dateComponentsForEpoch = [[NSDateComponents alloc] init];
    dateComponentsForEpoch.year = 2010;
    dateComponentsForEpoch.month = 1;
    dateComponentsForEpoch.day = 1;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    epoch = [calendar dateFromComponents:dateComponentsForEpoch];
}

+(NSArray *)pedometerServiceList
{
    static NSArray *pServices;
    static dispatch_once_t psOnceToken;
    dispatch_once(&psOnceToken, ^{
        pServices=@[@(PEDOMETER_SERVICE_UUID)];
    });
    return pServices;
}

+(NSArray *)weightScaleServiceList
{
    static NSArray *wServices;
    static dispatch_once_t wsOnceToken;
    dispatch_once(&wsOnceToken, ^{
        wServices=@[@(WEIGHTSCALE_SERVICE_UUID)];
    });
    return wServices;
}

+(NSArray *)heightScaleServiceList
{
    static NSArray *hServices;
    static dispatch_once_t hsOnceToken;
    dispatch_once(&hsOnceToken, ^{
        hServices=@[@(HEIGHT_SERVICE_UUID)];
    });
    return hServices;
}
+(NSArray *)sphygmometerServiceList
{
    static NSArray *sphyServices;
    static dispatch_once_t sphyOnceToken;
    dispatch_once(&sphyOnceToken, ^{
        sphyServices=@[@(BLOODPRESSURE_SERVICE_UUID),
                       @(BLOODPRESSURE_A3_SERVICE_UUID),
                       @(BLOODPRESSURE_COMMAND_START_SERVICE_UUID)];
    });
    return sphyServices;
}

+(NSArray *)fatScaleServiceList
{
    static NSArray *fatServices;
    static dispatch_once_t fsOnceToken;
    dispatch_once(&fsOnceToken, ^{
        fatServices=@[@(FAT_SCALE_A3_SERVICE_UUID),@(FAT_SCALE_A3_SALTER_SERVICE_UUID)];
    });
    return fatServices;
}

#pragma mark - public api

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



+(NSArray *)getServicesUuidByDeviceType:(LSDeviceType)deviceType
{
    if(deviceType==LS_WEIGHT_SCALE)
    {
        return [self weightScaleServiceList];
    }
    else if (deviceType==LS_HEIGHT_MIRIAM)
    {
        return [self heightScaleServiceList];
    }
    else if (deviceType==LS_PEDOMETER)
    {
        return [self pedometerServiceList];
    }
    else if (deviceType==LS_SPHYGMOMETER)
    {
        return [self sphygmometerServiceList];
    }
    else if(deviceType==LS_FAT_SCALE)
    {
        return  [self fatScaleServiceList];
    }
    else
    {
        return nil;
    }
    
}

+(NSString *)conversionServiceUUIDToString:(CBUUID *)uuid
{
    uint16_t uuidValue = [LSFormatConverter  uintValueWithCBUUID:uuid];
    if(uuidValue==DEVICEINFO_SERVICE_UUID)
    {
        return [NSString stringWithFormat:@"%d",DEVICEINFO_SERVICE_UUID];
    }
    else if(uuidValue==WEIGHTSCALE_SERVICE_UUID)
    {
        return [NSString stringWithFormat:@"%d",WEIGHTSCALE_SERVICE_UUID];
    }
    else if(uuidValue==HEIGHT_SERVICE_UUID)
    {
        return [NSString stringWithFormat:@"%d",HEIGHT_SERVICE_UUID];
    }
    else if(uuidValue==PEDOMETER_SERVICE_UUID)
    {
        return [NSString stringWithFormat:@"%d",PEDOMETER_SERVICE_UUID];
    }
    else if(uuidValue == BLOODPRESSURE_SERVICE_UUID)
    {
        return [NSString stringWithFormat:@"%d",BLOODPRESSURE_SERVICE_UUID];
    }
    else if(uuidValue==KITCHENSCALE_SERVICE_UUID)
    {
        return [NSString stringWithFormat:@"%d",KITCHENSCALE_SERVICE_UUID];
    }
    else if (uuidValue==BLOODPRESSURE_COMMAND_START_SERVICE_UUID)
    {
        return [NSString stringWithFormat:@"%d",BLOODPRESSURE_COMMAND_START_SERVICE_UUID];
    }
    else return @"Unknown";
    
}

+(NSString *)translateDeviceIdToSN:(NSString *)deviceId
{
    NSInteger firstPart = [self stringToInt32:[deviceId substringWithRange:NSMakeRange(0, 6)]];
    NSInteger secondPart = [self stringToInt32:[deviceId substringWithRange:NSMakeRange(6, 6)]];
    NSNumber *firstNumber = [NSNumber numberWithUnsignedInteger:firstPart];
    NSNumber *secondNumber = [NSNumber numberWithUnsignedInteger:secondPart];
    NSMutableString *firstString =[NSMutableString stringWithString:[firstNumber stringValue]];
    NSMutableString *secondString = [NSMutableString stringWithString:[secondNumber stringValue]];
    NSString *zeroString = [NSString stringWithFormat:@"0"];
    NSInteger length = 8 - firstString.length;
    for (int i = 0; i<length; i++) {
        
        [firstString insertString:zeroString atIndex:0];
    }
    length = 8-secondString.length;
    for (int i = 0; i<length; i++) {
        
        [secondString insertString:zeroString atIndex:0];
    }
    
    [firstString appendString:secondString];
    return firstString;
}

+(NSString *)deviceTypeWithInteger:(NSInteger)typeInteger
{
    NSString* typeString;
    if (typeInteger==LS_PEDOMETER) {
        typeString=[NSString stringWithFormat:@"计步器"];
    }
    if (typeInteger==LS_KITCHEN_SCALE) {
        typeString=[NSString stringWithFormat:@"厨房秤"];
    }
    if (typeInteger==LS_SPHYGMOMETER) {
        typeString=[NSString stringWithFormat:@"血压计"];
    }
    if (typeInteger==LS_HEIGHT_MIRIAM) {
        typeString=[NSString stringWithFormat:@"身高尺"];
    }
    if (typeInteger==LS_WEIGHT_SCALE) {
        typeString=[NSString stringWithFormat:@"体重秤"];
    }
    
    if (typeInteger==TYPE_UNKONW) {
        typeString=[NSString stringWithFormat:@"未知"];
    }
    
    return typeString;
}
+(NSString *)getProtocolTypeFromServices:(NSArray *)services
{
    NSString *protocolType=nil;
    if([services count])
    {
        NSArray *servicelist=nil;
        servicelist=[self getServiceListByProtocolType:@"A2"];
        if([servicelist count])
        {
            for (CBUUID *thisService in services)
            {
                uint16_t uuidValue =[LSFormatConverter uintValueWithCBUUID:thisService];
                
                if([servicelist containsObject:@(uuidValue)])
                {
                    return  protocolType=@"A2";
                }
            }
            
        }
        if(!protocolType)
        {
            servicelist=[self getServiceListByProtocolType:@"A3"];
            if([servicelist count])
            {
                for (CBUUID *thisService in services)
                {
                    uint16_t uuidValue =[LSFormatConverter uintValueWithCBUUID:thisService];
                    
                    if([servicelist containsObject:@(uuidValue)])
                    {
                        return  protocolType=@"A3";
                    }
                }
            }
            
            servicelist=[self getServiceListByProtocolType:@"GENERIC_FAT"];
            if([servicelist count])
            {
                for (CBUUID *thisService in services)
                {
                    uint16_t uuidValue =[LSFormatConverter uintValueWithCBUUID:thisService];
                    
                    if([servicelist containsObject:@(uuidValue)])
                    {
                        return  protocolType=@"GENERIC_FAT";
                    }
                }
            }
            servicelist=[self getServiceListByProtocolType:@"KITCHEN_SCALE"];
            if([servicelist count])
            {
                for (CBUUID *serviceUUID in services)
                {
                    uint16_t uuidValue =[LSFormatConverter uintValueWithCBUUID:serviceUUID];
                    
                    if([servicelist containsObject:@(uuidValue)])
                    {
                        return  protocolType=@"KITCHEN_SCALE";
                    }
                }
            }
            servicelist=[self getServiceListByProtocolType:@"SALTER_MIBODY"];
            if([servicelist count])
            {
                for (CBUUID *serviceUUID in services)
                {
                    uint16_t uuidValue =[LSFormatConverter uintValueWithCBUUID:serviceUUID];
                    
                    if([servicelist containsObject:@(uuidValue)])
                    {
                        return  protocolType=@"SALTER_MIBODY";
                    }
                }
            }
            servicelist=[self getServiceListByProtocolType:@"COMMAND_START"];
            if ([servicelist count])
            {
                for(CBUUID *serviceUUID in services)
                {
                    uint16_t uuidValue =[LSFormatConverter uintValueWithCBUUID:serviceUUID];
                    
                    if([servicelist containsObject:@(uuidValue)])
                    {
                        return  protocolType=@"COMMAND_START";
                        
                    }
                }
            }
            servicelist=[self getServiceListByProtocolType:@"A3_1"];
            if([servicelist count])
            {
                for(CBUUID *serviceUUID in services)
                {
                    uint16_t uuidValue =[LSFormatConverter uintValueWithCBUUID:serviceUUID];
                    
                    if([servicelist containsObject:@(uuidValue)])
                    {
                        return  protocolType=@"A3_1";
                        
                    }
                }
                
            }
            
        }
    }
    
    return protocolType;
    
}

+(LSDeviceType)getDeviceTypeFromServices:(NSArray*)serviceList
{
    if([serviceList count])
    {
        for (CBUUID *service in serviceList)
        {
            uint16_t uuidValue =[LSFormatConverter uintValueWithCBUUID:service];
            if(uuidValue == WEIGHTSCALE_SERVICE_UUID)
            {
                return LS_WEIGHT_SCALE;
            }
            else if(uuidValue == PEDOMETER_SERVICE_UUID)
            {
                return LS_PEDOMETER;
            }
            else if(uuidValue == BLOODPRESSURE_SERVICE_UUID )
            {
                return LS_SPHYGMOMETER;
            }
            else if(uuidValue == HEIGHT_SERVICE_UUID)
            {
                return LS_HEIGHT_MIRIAM;
            }
            else if(uuidValue == KITCHENSCALE_SERVICE_UUID)
            {
                return LS_KITCHEN_SCALE;
            }
            else if(uuidValue==GENERAL_WEIGHT_SCALE_SERVICE_UUID)
            {
                return LS_WEIGHT_SCALE;
            }
            else if(uuidValue==FAT_SCALE_A3_SERVICE_UUID
                    || uuidValue==FAT_SCALE_A3_SALTER_SERVICE_UUID
                    || uuidValue==FAT_SCALE_A3_PHILIPS_SERVICE_UUID)
            {
                return LS_FAT_SCALE;
            }
            else if(uuidValue==BLOODPRESSURE_A3_SERVICE_UUID
                    || uuidValue==BLOODPRESSURE_COMMAND_START_SERVICE_UUID
                    || uuidValue==BLOODPRESSURE_A3_PHILIPS_SERVICE_UUID)
            {
                return LS_SPHYGMOMETER;
            }
            else return TYPE_UNKONW;
        }
        return TYPE_UNKONW;
    }
    else return TYPE_UNKONW;
}


+(NSString*)getModelNumberFromBroadcastName:(NSString*)broadcastName
{
    if(broadcastName.length==0 || broadcastName.length <=6)
    {
        return nil;
    }
    NSString *tempName =[broadcastName substringWithRange:NSMakeRange(1, 5)];
    int index = -1;
    NSString *modelNumber = nil;
    if (isChineseVersion())
    {
        NSArray *array = @[@"101A0", @"102B ", @"103B ", @"202B ", @"203B ", @"305A0", @"401A0", @"405A0", @"802A0", @"805A0", @"102B0", @"202B0"];
        if ([array containsObject:tempName])
        {
            index = (int)[array indexOfObject:tempName];
            switch (index) {
                case 0:
                    modelNumber = @"LS101-B";
                    break;
                case 1:
                    modelNumber = @"LS102-B";
                    break;
                case 2:
                    modelNumber = @"A3(BT)";
                    break;
                case 3:
                    modelNumber = @"LS202-B";
                    break;
                case 4:
                    modelNumber = @"LS203-B";
                    break;
                case 5:
                    modelNumber = @"LS305-B";
                    break;
                case 6:
                    modelNumber = @"LS401-B";
                    break;
                case 7:
                    modelNumber = @"LS405-B";
                    break;
                case 8:
                    modelNumber = @"LS802(BT4.0)";
                    break;
                case 9:
                    modelNumber = @"LS805(BT4.0)";
                    break;
                case 10:
                    modelNumber = @"LS102-B";
                    break;
                case 11:
                    modelNumber = @"LS202-B";
                    break;
                default:
                    break;
            }
            
        }
        else{
            modelNumber = [NSString stringWithFormat:@"LS%@", tempName];
        }
    }
    else
    {
        NSArray *array = @[@"1136B", @"102B ", @"103B ", @"106A0", @"202B ", @"203B ", @"1251B", @"1255B", @"1256B",@"1257B", @"1144B", @"12670", @"1014B", @"810A0", @"802A0", @"805A0", @"1018B", @"406A0", @"402A0", @"102B1", @"202B5", @"203B0", @"12510", @"12550",@"203B1",@"203B2", @"10140", @"802A1", @"805A1", @"10141", @"802A2", @"10142", @"802A3", @"10143", @"802A4", @"10144", @"10145", @"10146", @"SFBS1"];
        if ([array containsObject:tempName])
        {
            index = (int)[array indexOfObject:tempName];
            switch (index)
            {
                case 0:
                    modelNumber = @"GKS-1136-BT";
                    break;
                case 1:
                    modelNumber = @"LS102-B";
                    break;
                case 2:
                    modelNumber = @"LS103-B";
                    break;
                case 3:
                    modelNumber = @"BS-705-BT";
                    break;
                case 4:
                    modelNumber = @"LS202-B";
                    break;
                case 5:
                    modelNumber= @"LS203-B";
                    break;
                case 6:
                    modelNumber = @"GBF-1251-B";
                    break;
                case 7:
                    modelNumber = @"BF-1255-B";
                    break;
                case 8:
                    modelNumber = @"BF-1256-B";
                    break;
                case 9:
                    modelNumber = @"GBF-1257-B";
                    break;
                case 10:
                    modelNumber = @"GBF-1144-B";
                    break;
                case 11:
                    modelNumber = @"WEB COACH";
                    break;
                case 12:
                    modelNumber = @"TMB-1014-BT";
                    break;
                case 13:
                    modelNumber = @"LS810-B/TENSIO";
                    break;
                case 14:
                    modelNumber = @"LS802-B";
                    break;
                case 15:
                    modelNumber = @"LS805-B";
                    break;
                case 16:
                    modelNumber = @"TMB-1018-BT";
                    break;
                case 17:
                    modelNumber = @"LS406-B";
                    break;
                case 18:
                    modelNumber = @"LS402-B";
                    break;
                case 19:
                    modelNumber = @"LS102-B";
                    break;
                case 20:
                    modelNumber = @"202";
                    break;
                case 21:
                    modelNumber = @"vs-3200-w";
                    break;
                case 22:
                    modelNumber = @"GBF-1251-B";
                    break;
                case 23:
                    modelNumber = @"vs-3100";
                    break;
                case 24:
                    modelNumber = @"vs-3200-b";
                    break;
                case 25:
                    modelNumber = @"9154 BK3R";
                    break;
                case 26:
                    modelNumber = @"vs-4300-w";
                    break;
                case 27:
                    modelNumber = @"vs-4400";
                    break;
                case 28:
                    modelNumber = @"vs-4000";
                    break;
                case 29:
                    modelNumber= @"vs-4300-b";
                    break;
                case 30:
                    modelNumber = @"LS802-B";
                    break;
                case 31:
                    modelNumber = @"TMB-1014-BT";
                    break;
                case 32:
                    modelNumber = @"LS802-B";
                    break;
                case 33:
                    modelNumber = @"RWBPM01";
                    break;
                case 34:
                    modelNumber = @"TENSIO SCREEN";
                    break;
                case 35:
                    modelNumber = @"TMB-1014-BT";
                    break;
                case 36:
                    modelNumber = @"TMB-1014-BT";
                    break;
                case 37:
                    modelNumber = @"BPW-9154";
                    break;
                case 38:
                    modelNumber = @"SFBS1-BT";
                    break;
                    
                default:
                    break;
            }
        }
        else{
            modelNumber = [NSString stringWithFormat:@"LS%@", tempName];
        }
    }
    
    return modelNumber;
}

+(uint16_t)uintValueWithCBUUID:(CBUUID* )cbuuid
{
    uint8_t *byte = (uint8_t *)[cbuuid.data bytes];
    uint16_t result = 0;
    result = *byte;
    byte++;
    result = result<<8;
    result = result |(*byte);
    return result;
}

+(NSString *)uuidLogogramValue:(NSString *)uuid
{
    NSString *value=uuid;
    if(uuid.length > 8)
    {
        
        value=[uuid substringWithRange: NSMakeRange(4, 4)];
    }
    return value;
    
}

+(BOOL)checkCustomBroadcastID:(NSString *)customBroadcastId
{
    if(customBroadcastId.length)
    {
        NSString *regex=@"[0-9a-fA-F]{8}";
        NSPredicate *predicate=[NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
        return [predicate evaluateWithObject:customBroadcastId];
    }
    else
    {
        [BleDebugLogger object:self printMessage:@"Error,an invalid broadcast id format..." withDebugLevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
    
}


#pragma mark - private methods

+(NSArray *)getServiceListByProtocolType:(NSString *)protocolType
{
    NSArray *services=nil;
    if([protocolType isEqualToString:@"A2"])
    {
        return  services=@[@(WEIGHTSCALE_SERVICE_UUID),
                           @(HEIGHT_SERVICE_UUID),
                           @(PEDOMETER_SERVICE_UUID),
                           @(BLOODPRESSURE_SERVICE_UUID)];
    }
    else if([protocolType isEqualToString:@"A3"])
    {
        return services=@[@(FAT_SCALE_A3_SERVICE_UUID),
                          @(BLOODPRESSURE_A3_SERVICE_UUID)];
        
    }
    else if([protocolType isEqualToString:@"GENERIC_FAT"])
    {
        return services=@[@(GENERIC_FAT_SCALE_SERVICE_UUID)];
        
    }
    else if([protocolType isEqualToString:@"KITCHEN_SCALE"])
    {
        return services=@[@(KITCHENSCALE_SERVICE_UUID)];
    }
    else if ([protocolType isEqualToString:@"SALTER_MIBODY"])
    {
        return services=@[@(FAT_SCALE_A3_SALTER_SERVICE_UUID)];
    }
    else if ([protocolType isEqualToString:@"COMMAND_START"])
    {
        return services=@[@(BLOODPRESSURE_COMMAND_START_SERVICE_UUID)];
    }
    else if ([protocolType isEqualToString:@"A3_1"])
    {
        return services=@[@(BLOODPRESSURE_A3_PHILIPS_SERVICE_UUID),
                          @(FAT_SCALE_A3_PHILIPS_SERVICE_UUID)];
    }
    
    else return nil;
}

+(uint32_t)stringToInt32:(NSString*)subString
{
    NSString *lowcaseString = [subString lowercaseString];
    char *characterPoint = (char*)[lowcaseString UTF8String];
    uint32_t result = 0;
    
    for (int i = 0; i<[lowcaseString length]; i++) {
        
        result = result<<4;
        char localChar = *characterPoint;
        uint8_t localInt = 0;
        if (localChar>='0'&&localChar<='9') {
            
            localInt = localChar-'0';
        }
        if (localChar>='a'&&localChar<='f') {
            
            localInt = localChar - 'a' +10;
        }
        result = result |localInt;
        characterPoint++;
    }
    
    return result;
}

static const BOOL isChineseVersion()
{
    BOOL result = NO;
    NSArray *array = [[NSUserDefaults standardUserDefaults]objectForKey:@"AppleLanguages"];
    NSString *currentLanguage = [array objectAtIndex:0];
    //NSLog(@"currentLanguage = %@", currentLanguage);
    if ([currentLanguage isEqualToString:@"zh-Hans"])
    {
        NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
        NSString *timeZoneName = timeZone.name;
        //NSLog(@"timeZoneName = %@", timeZoneName);
        if ([timeZoneName isEqualToString:@"Asia/Shanghai"] ||[timeZoneName isEqualToString:@"Asia/Chongqing"]||[timeZoneName isEqualToString:@"Asia/Macau"]||[timeZoneName isEqualToString:@"Asia/Taipei"]||[timeZoneName isEqualToString:@"Asia/Harbin"]||[timeZoneName isEqualToString:@"Asia/Hong_kong"])
        {
            result = YES;
        }
    }
    
    return result;
}

+(NSUInteger)currentUTC
{
    //    //new change for version 3.0.5
    //    NSCalendar*calendar=[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    //    [calendar setLocale:[NSLocale currentLocale]];
    //
    //    NSDate*date=[NSDate date];
    //    NSDateComponents*componets=[calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:date];
    //
    //    NSString* year=[NSString stringWithFormat:@"%ld",[componets year]];
    //    NSString*month;
    //    if ([componets month]>9) {
    //        month=[NSString stringWithFormat:@"%ld",[componets month]];
    //    }else{
    //        month=[NSString stringWithFormat:@"%0ld",[componets month]];
    //    }
    //    NSString*day;
    //    if ([componets day]>9) {
    //        day=[NSString stringWithFormat:@"%ld",[componets day]];
    //    }else{
    //        day=[NSString stringWithFormat:@"%0ld",[componets day]];
    //    }
    //    NSString*hour;
    //    if ([componets hour]>9) {
    //        hour=[NSString stringWithFormat:@"%ld",[componets hour]];
    //    }else{
    //        hour=[NSString stringWithFormat:@"0%ld",[componets hour]];
    //    }
    //    NSString*minute;
    //    if ([componets minute]>9) {
    //        minute=[NSString stringWithFormat:@"%ld",[componets minute]];
    //    }else{
    //        minute=[NSString stringWithFormat:@"0%ld",[componets minute]];
    //    }
    //    NSString*second;
    //    if ([componets second]>9) {
    //        second=[NSString stringWithFormat:@"%ld",[componets second]];
    //    }else{
    //        second=[NSString stringWithFormat:@"0%ld",[componets second]];
    //    }
    //    NSString*dateString1=@"2010-01-01 00:00:00";
    //    NSString*dateString2=[NSString stringWithFormat:@"%@-%@-%@ %@:%@:%@",year,month,day,hour,minute,second];
    //    NSDateFormatter*formatter=[[NSDateFormatter alloc] init];
    //    //set locale
    //    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
    //    //set time zone
    //    NSTimeZone*timeZone=[[NSTimeZone alloc] initWithName:@"Asia/Shanghai"];
    //    [formatter setTimeZone:timeZone];
    //    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    //    NSDate*date1=[formatter dateFromString:dateString1];
    //    NSDate*date2=[formatter dateFromString:dateString2];
    //    NSUInteger utcValue=[date2 timeIntervalSinceDate:date1];
    //    return utcValue;
    
    NSDate *currentTime = [NSDate date];
    return [currentTime timeIntervalSinceDate:epoch];
}

+(NSString *)dateFromUTC:(NSUInteger)utc
{
    //    NSDateFormatter*formatter=[[NSDateFormatter alloc] init];
    //    //set locale
    //    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
    //    //set time zone
    //    NSTimeZone*timeZone=[[NSTimeZone alloc] initWithName:@"Asia/Shanghai"];
    //    [formatter setTimeZone:timeZone];
    //    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    //    NSString*dateString1=@"2010-01-01 00:00:00";
    //    NSDate*date1=[formatter dateFromString:dateString1];
    //    NSDate*date2=[date1 dateByAddingTimeInterval:utc];
    //    NSString *timeString=[formatter stringFromDate:date2];
    //    return timeString;
    NSDate *actualDate = [epoch dateByAddingTimeInterval:utc];
    NSDateFormatter*formatter=[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
    NSString *timeString=[formatter stringFromDate:actualDate];
    return timeString;
}


+(NSString *)uint32toHexString:(uint32_t)value
{
    //    NSLog(@"把32为无符号整数转换成16进制的字符串:%@",[NSString stringWithFormat:@"%x",value]);
    NSString*str0=[NSString stringWithFormat:@"%x",value];
    if([str0 length]<8)
    {
        for (int i=0; i<8-[str0 length]; i++)
        {
            str0=[NSString stringWithFormat:@"0%@",str0];
        }
    }
    NSString*str1=[str0 substringWithRange:NSMakeRange(0, 2)];
    NSString*str2=[str0 substringWithRange:NSMakeRange(2, 2)];;
    NSString*str3=[str0 substringWithRange:NSMakeRange(4, 2)];;
    NSString*str4=[str0 substringWithRange:NSMakeRange(6, 2)];;
    NSString*str5=[NSString stringWithFormat:@"%@%@%@%@",str4,str3,str2,str1];
    
    return [str5 uppercaseString];
}
+(NSUInteger)hexStringUnsignedInteger:(NSString*)hexString
{
    NSString*tmp1=[hexString substringWithRange:NSMakeRange(0, 2)];
    NSString*tmp2=[hexString substringWithRange:NSMakeRange(2, 2)];
    NSString*tmp3=[hexString substringWithRange:NSMakeRange(4, 2)];
    NSString*tmp4=[hexString substringWithRange:NSMakeRange(6, 2)];
    NSString*tmp5=[NSString stringWithFormat:@"0x%@%@%@%@",tmp4,tmp3,tmp2,tmp1];
    unsigned long long i;
    //    NSLog(@"16进制字符转换成数字：%@",tmp5);
    NSScanner*scanner=[NSScanner scannerWithString:tmp5];
    [scanner scanHexLongLong:&i];
    
    //    NSLog(@"16进制字符转换成数字：%llu",i);
    return i;
}

+(NSString *)formattingValidUTF8:(NSData *)sourceData
{
    if(!sourceData.length)
    {
        return nil;
    }
    NSString *utf8=[[NSString alloc] initWithData:sourceData encoding:NSUTF8StringEncoding];
    if(utf8.length)
    {
        return utf8;
    }
    NSData *validData=[[NSData alloc] initWithData:sourceData];
    NSUInteger chineseChar=[self countChineseCharacter:sourceData];
    //由于一个中文字符转成utf-8编码后，占用3个字节
    //因此解析时需要还去掉缺少的字节部分，否则调用无法将NSData转成NSString
    NSUInteger index=chineseChar % 3;
    validData=[sourceData subdataWithRange:NSMakeRange(0, sourceData.length-index)];
    return [[NSString alloc] initWithData:validData encoding:NSUTF8StringEncoding];
}

/**
 * 计算英文字符的个数
 */
+(NSUInteger)countAsciiCharacter:(NSData *)data
{
    if(!data.length)
    {
        return 0;
    }
    uint8_t *byte=(uint8_t *)data.bytes;
    NSUInteger characterCount=0;
    for(NSUInteger i=0;i<data.length;i++)
    {
        if(byte[i] <= 127)
        {
            characterCount++;
        }
    }
    return characterCount;
}

/**
 * 计算中文字符的个数
 */
+(NSUInteger)countChineseCharacter:(NSData *)data
{
    if(!data.length)
    {
        return 0;
    }
    uint8_t *byte=(uint8_t *)data.bytes;
    NSUInteger characterCount=0;
    for(NSUInteger i=0;i<data.length;i++)
    {
        if(byte[i] > 127)
        {
            characterCount++;
        }
    }
    return characterCount;
}

@end
