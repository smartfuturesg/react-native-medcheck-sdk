//
//  DataFormatConverter.h
//  LSBluetooth-Demo
//
//  Created by lifesense on 15/8/20.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSBluetoothComponents.h"
#import "BleDevice+CoreDataClass.h"
#import "BleDevice+CoreDataProperties.h"
#import <UIKit/UIKit.h>
#import "DeviceAlarmClock+CoreDataProperties.h"
#import "DeviceAlarmClock+CoreDataClass.h"
#import "DeviceUser+CoreDataProperties.h"
#import "DeviceUser+CoreDataClass.h"
#import "DeviceUserProfiles+CoreDataClass.h"
#import "DeviceUserProfiles+CoreDataProperties.h"


@interface DataFormatConverter : NSObject

+(LSDeviceType)stringToDeviceType:(id)type;

+(LSDeviceInfo *)convertedToLSDeviceInfo:(BleDevice *)bleDevice;

+(NSString *)doubleValueWithOneDecimalFormat:(double)weightValue;

+(NSString *)doubleValueWithTwoDecimalFormat:(double)weightValue;

+(UIImage *)getDeviceImageViewWithType:(LSDeviceType)deviceType;

+(NSString *)getDeviceNameForNormalBroadcasting:(NSString *)deviceName;

+(BOOL)isNotRequiredPairDevice:(NSString *)protocol;

+(NSDictionary *)parseObjectDetailInDictionary:(id)obj;

+(NSString *)parseObjectDetailInStringValue:(id)obj;

+(NSAttributedString *)parseObjectDetailInAttributedString:(id)obj recordNumber:(NSUInteger)number;

+(int)getAlarmClockDayCount:(DeviceAlarmClock *)deviceAlarmClock;

+(LSPedometerAlarmClock *)getPedometerAlarmClock:(DeviceAlarmClock *)deviceAlarmClock;

+(LSPedometerUserInfo *)getPedometerUserInfo:(DeviceUser *)deviceUser;

+(LSProductUserInfo *)getProductUserInfo:(DeviceUser *)deviceUser;

@end
