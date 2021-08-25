//
//  DeviceAlarmClock+CoreDataProperties.m
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "DeviceAlarmClock+CoreDataProperties.h"

@implementation DeviceAlarmClock (CoreDataProperties)

+ (NSFetchRequest<DeviceAlarmClock *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"DeviceAlarmClock"];
}

@dynamic alarmClockDay;
@dynamic alarmClockId;
@dynamic alarmClockTime;
@dynamic friday;
@dynamic monday;
@dynamic saturday;
@dynamic sunday;
@dynamic thursday;
@dynamic tuesday;
@dynamic wednesday;
@dynamic deviceUser;

@end
