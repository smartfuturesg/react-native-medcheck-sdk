//
//  DeviceUserProfiles+CoreDataProperties.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "DeviceUserProfiles+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DeviceUserProfiles (CoreDataProperties)

+ (NSFetchRequest<DeviceUserProfiles *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *alarmClockId;
@property (nullable, nonatomic, copy) NSString *distanceUnit;
@property (nullable, nonatomic, copy) NSString *hourFormat;
@property (nullable, nonatomic, copy) NSString *scanFilterId;
@property (nullable, nonatomic, copy) NSString *userId;
@property (nullable, nonatomic, copy) NSString *weekStart;
@property (nullable, nonatomic, copy) NSNumber *weekTargetSteps;
@property (nullable, nonatomic, copy) NSNumber *weightTarget;
@property (nullable, nonatomic, copy) NSString *weightUnit;
@property (nullable, nonatomic, retain) DeviceAlarmClock *deviceAlarmClock;
@property (nullable, nonatomic, retain) ScanFilter *hasScanFilter;
@property (nullable, nonatomic, retain) DeviceUser *whoSet;

@end

NS_ASSUME_NONNULL_END
