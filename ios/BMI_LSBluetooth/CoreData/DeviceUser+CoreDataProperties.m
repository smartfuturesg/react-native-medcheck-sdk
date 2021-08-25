//
//  DeviceUser+CoreDataProperties.m
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "DeviceUser+CoreDataProperties.h"

@implementation DeviceUser (CoreDataProperties)

+ (NSFetchRequest<DeviceUser *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"DeviceUser"];
}

@dynamic athleteLevel;
@dynamic birthday;
@dynamic gender;
@dynamic height;
@dynamic name;
@dynamic userID;
@dynamic weight;
@dynamic devices;
@dynamic userprofiles;

@end
