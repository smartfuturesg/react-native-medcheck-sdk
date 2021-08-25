//
//  DeviceUserProfiles+CoreDataClass.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define KEY_USER_PROFILES_ID                        @"userId"
#define KEY_USER_PROFILES_ALARM_CLOCK_ID            @"alarmClockId"
#define KEY_USER_PROFILES_SCAN_FILTER_ID            @"scanFilterId"
#define KEY_USER_PROFILES_DISTANCE_UNIT             @"distanceUnit"
#define KEY_USER_PROFILES_HOUR_FORMAT               @"hourFormat"
#define KEY_USER_PROFILES_WEEK_START                @"weekStart"
#define KEY_USER_PROFILES_WEEK_TARGET_STEPS         @"weekTargetSteps"
#define KEY_USER_PROFILES_WEIGHT_TARGET             @"weightTarget"
#define KEY_USER_PROFILES_WEIGHT_UNIT               @"weightUnit"

@class DeviceAlarmClock, DeviceUser, ScanFilter;

NS_ASSUME_NONNULL_BEGIN

@interface DeviceUserProfiles : NSManagedObject
+(DeviceUserProfiles *)createUserProfilesWithInfo:(NSDictionary *)profilesInfo
                           inManagedObjectContext:(NSManagedObjectContext *)context;

+(DeviceUserProfiles *)bindUserProfilesWithAlarmClockID:(NSString *)alarmClockId
                                 inManagedObjectContext:(NSManagedObjectContext *)context;

+(DeviceUserProfiles *)bindUserProfilesWithScanFilterId:(NSString *)scanFilterId
                                 inManagedObjectContext:(NSManagedObjectContext *)context;
@end

NS_ASSUME_NONNULL_END

#import "DeviceUserProfiles+CoreDataProperties.h"
