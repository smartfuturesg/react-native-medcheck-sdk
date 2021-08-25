//
//  DeviceAlarmClock+CoreDataProperties.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "DeviceAlarmClock+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DeviceAlarmClock (CoreDataProperties)

+ (NSFetchRequest<DeviceAlarmClock *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *alarmClockDay;
@property (nullable, nonatomic, copy) NSString *alarmClockId;
@property (nullable, nonatomic, copy) NSDate *alarmClockTime;
@property (nullable, nonatomic, copy) NSNumber *friday;
@property (nullable, nonatomic, copy) NSNumber *monday;
@property (nullable, nonatomic, copy) NSNumber *saturday;
@property (nullable, nonatomic, copy) NSNumber *sunday;
@property (nullable, nonatomic, copy) NSNumber *thursday;
@property (nullable, nonatomic, copy) NSNumber *tuesday;
@property (nullable, nonatomic, copy) NSNumber *wednesday;
@property (nullable, nonatomic, retain) DeviceUserProfiles *deviceUser;

@end

NS_ASSUME_NONNULL_END
