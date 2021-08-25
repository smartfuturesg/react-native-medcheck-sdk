//
//  BleDevice+CoreDataClass.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "LSBluetoothComponents.h"

@class DeviceUser;

NS_ASSUME_NONNULL_BEGIN

@interface BleDevice : NSManagedObject
+(BleDevice *)bindDeviceWithUserId:(NSString *)userId
                        deviceInfo:(LSDeviceInfo *)lsDeviceInfo
            inManagedObjectContext:(NSManagedObjectContext *)context;

+(void)deleteBleDevice:(BleDevice *)delDevice inManagedObjectContext:(NSManagedObjectContext *)context;
@end

NS_ASSUME_NONNULL_END

#import "BleDevice+CoreDataProperties.h"
