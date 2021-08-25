//
//  ScanFilter+CoreDataClass.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define KEY_SCAN_FILTER_ID              @"scanFilterId"
#define KEY_SCAN_FILTER_BROADCAST       @"broadcastType"
#define KEY_SCAN_FILTER_FAT_SCALE       @"enableFatScale"
#define KEY_SCAN_FILTER_WEIGHT_SCALE    @"enableWeightScale"
#define KEY_SCAN_FILTER_PEDOMETER       @"enablePedometer"
#define KEY_SCAN_FILTER_HEIGHT          @"enableHeightMeter"
#define KEY_SCAN_FILTER_BLOOD_PRESSURE  @"enableBloodPressure"
#define KEY_SCAN_FILTER_KITCHEN         @"enableKitchenScale"

@class DeviceUserProfiles;

NS_ASSUME_NONNULL_BEGIN

@interface ScanFilter : NSManagedObject
+(ScanFilter *)createScanFilterWithInfo:(NSDictionary *)scanFilterInfo
                 inManagedObjectContext:(NSManagedObjectContext *)context;
@end

NS_ASSUME_NONNULL_END

#import "ScanFilter+CoreDataProperties.h"
