//
//  DeviceUserProfiles+CoreDataProperties.m
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "DeviceUserProfiles+CoreDataProperties.h"

@implementation DeviceUserProfiles (CoreDataProperties)

+ (NSFetchRequest<DeviceUserProfiles *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"DeviceUserProfiles"];
}

@dynamic alarmClockId;
@dynamic distanceUnit;
@dynamic hourFormat;
@dynamic scanFilterId;
@dynamic userId;
@dynamic weekStart;
@dynamic weekTargetSteps;
@dynamic weightTarget;
@dynamic weightUnit;
@dynamic deviceAlarmClock;
@dynamic hasScanFilter;
@dynamic whoSet;

@end
