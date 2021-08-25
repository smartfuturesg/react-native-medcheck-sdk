//
//  ScanFilter+CoreDataProperties.m
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "ScanFilter+CoreDataProperties.h"

@implementation ScanFilter (CoreDataProperties)

+ (NSFetchRequest<ScanFilter *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"ScanFilter"];
}

@dynamic broadcastType;
@dynamic enableBloodPressure;
@dynamic enableFatScale;
@dynamic enableHeightMeter;
@dynamic enableKitchenScale;
@dynamic enablePedometer;
@dynamic enableWeightScale;
@dynamic filterId;
@dynamic deviceUser;

@end
