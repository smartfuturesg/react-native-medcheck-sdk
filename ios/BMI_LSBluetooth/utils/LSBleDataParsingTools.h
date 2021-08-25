//
//  LSBleDataParsingTools.h
//  LsBluetooth-Test
//
//  Created by lifesense on 14-8-4.
//  Copyright (c) 2014年 com.lifesense.ble. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BleManagerProfiles.h"
#import "LSWeightData.h"
#import "LSHeightData.h"
#import "LSKitchenScaleData.h"
#import "LSSphygmometerData.h"
#import "LSPedometerData.h"
#import "LSWeightAppendData.h"
#import "LSProductUserInfo.h"
#import "LSDeviceInfo.h"
#import "LSBlePairingDelegate.h"
#import "LSBleDataReceiveDelegate.h"
#import "LSPedometerUserInfo.h"
#import "LSPedometerAlarmClock.h"
#import "LSVibrationVoice.h"
#import "LSDeviceConnectDelegate.h"
#import "LSSleepRecord.h"

@interface LSBleDataParsingTools : NSObject

+(LSWeightData*)parseWeightAppendDataWithNormalWeight:(LSWeightData *) normalWeightDdata sourceData:(NSData*)data;

+(LSWeightAppendData*)parseWeightAppendData:(NSData*)data;

+(LSWeightData*)parseWeightScaleMeasurementData:(NSData*)data;

+(LSSphygmometerData*)parseSphygmometerMeasurementData:(NSData*)data;

+(LSPedometerData*)parsePedometerScaleMeasurementData:(NSData*)data;

+(LSKitchenScaleData*)parseKitchenMeasurementData:(NSData*)data;

+(LSHeightData*)parseHeightMeasurementData:(NSData*)data;

+(double)translateToSFloat:(uint16_t)data;


@end
