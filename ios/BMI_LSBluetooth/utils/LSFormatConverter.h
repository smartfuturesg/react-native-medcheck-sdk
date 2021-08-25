//
//  LSFormatConverter.h
//  LifesenseBle
//
//  Created by lifesense on 14-8-2.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSDeviceInfo.h"
#import <CoreBluetooth/CBUUID.h>

@interface LSFormatConverter : NSObject

+(NSDictionary *)dictionaryWithProperty:(id)obj;

+(uint16_t)uintValueWithCBUUID:(CBUUID* )cbuuid;

+(NSString *)deviceTypeWithInteger:(NSInteger)typeInteger;

+(LSDeviceType)getDeviceTypeFromServices:(NSArray*)serviceList;

+(NSString*)getModelNumberFromBroadcastName:(NSString*)broadcastName;


+(NSString *)translateDeviceIdToSN:(NSString *)deviceId;

+(NSString *)conversionServiceUUIDToString:(CBUUID *)uuid;

+(NSUInteger)currentUTC;

+(NSString *)dateFromUTC:(NSUInteger)utc;


+(NSArray *)getServicesUuidByDeviceType:(LSDeviceType)deviceType;

+(NSString *)getProtocolTypeFromServices:(NSArray *)services;

+(NSString *)utcToDateString:(NSUInteger)utc;

+(NSString *)uint32toHexString:(uint32_t)value;

+(NSUInteger)hexStringUnsignedInteger:(NSString*)hexString;

//获取UUID的简写形式
+(NSString *)uuidLogogramValue:(NSString *)uuid;

+(BOOL)checkCustomBroadcastID:(NSString *)customBroadcastId;

+(NSString *)formattingValidUTF8:(NSData *)sourceData;


@end
