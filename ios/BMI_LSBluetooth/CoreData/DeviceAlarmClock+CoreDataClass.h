//
//  DeviceAlarmClock+CoreDataClass.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define KEY_ALARM_CLOCK_ID          @"alarmClockId"
#define KEY_ALARM_CLOCK_MONDAY      @"monday"
#define KEY_ALARM_CLOCK_TUESDAY     @"tuesday"
#define KEY_ALARM_CLOCK_WEDNESDAY   @"wednesday"
#define KEY_ALARM_CLOCK_THURSDAY    @"thursday"
#define KEY_ALARM_CLOCK_FRIDAY      @"friday"
#define KEY_ALARM_CLOCK_SATURDAY    @"saturday"
#define KEY_ALARM_CLOCK_SUNDAY      @"sunday"
#define KEY_ALARM_CLOCK_TIME        @"alarmClockTime"
#define KEY_ALARM_CLOCK_DAY         @"alarmClockDay"

@class DeviceUserProfiles;

NS_ASSUME_NONNULL_BEGIN

@interface DeviceAlarmClock : NSManagedObject
+(DeviceAlarmClock *)createAlarmClockWithInfo:(NSDictionary *)alarmClockInfo
                       inManagedObjectContext:(NSManagedObjectContext *)context;
@end

NS_ASSUME_NONNULL_END

#import "DeviceAlarmClock+CoreDataProperties.h"
