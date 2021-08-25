//
//  ScanFilter+CoreDataProperties.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "ScanFilter+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ScanFilter (CoreDataProperties)

+ (NSFetchRequest<ScanFilter *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *broadcastType;
@property (nullable, nonatomic, copy) NSNumber *enableBloodPressure;
@property (nullable, nonatomic, copy) NSNumber *enableFatScale;
@property (nullable, nonatomic, copy) NSNumber *enableHeightMeter;
@property (nullable, nonatomic, copy) NSNumber *enableKitchenScale;
@property (nullable, nonatomic, copy) NSNumber *enablePedometer;
@property (nullable, nonatomic, copy) NSNumber *enableWeightScale;
@property (nullable, nonatomic, copy) NSString *filterId;
@property (nullable, nonatomic, retain) DeviceUserProfiles *deviceUser;

@end

NS_ASSUME_NONNULL_END
