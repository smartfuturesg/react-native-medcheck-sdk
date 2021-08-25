//
//  BleDevice+CoreDataProperties.m
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "BleDevice+CoreDataProperties.h"

@implementation BleDevice (CoreDataProperties)

+ (NSFetchRequest<BleDevice *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"BleDevice"];
}

@dynamic broadcastID;
@dynamic deviceID;
@dynamic deviceName;
@dynamic deviceSN;
@dynamic deviceType;
@dynamic deviceUserNumber;
@dynamic firmwareVersion;
@dynamic hardwareVersion;
@dynamic identifier;
@dynamic modelNumber;
@dynamic password;
@dynamic protocolType;
@dynamic softwareVersion;
@dynamic userId;
@dynamic whoBind;

@end
