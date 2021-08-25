//
//  DeviceUser+CoreDataClass.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define DEVICE_USER_KEY_ID              @"userId"
#define DEVICE_USER_KEY_NAME            @"userName"
#define DEVICE_USER_KEY_GENDER          @"userGender"
#define DEVICE_USER_KEY_BIRTHDAY        @"birthday"
#define DEVICE_USER_KEY_HEIGHT          @"height"
#define DEVICE_USER_KEY_WEIGHT          @"weight"
#define DEVICE_USER_KEY_ATHLETELEVEL    @"athleteLevel"

@class BleDevice, DeviceUserProfiles;

NS_ASSUME_NONNULL_BEGIN

@interface DeviceUser : NSManagedObject
+(DeviceUser *)createDeviceUserWithUserInfo:(NSDictionary *)userInfo
                     inManagedObjectContext:(NSManagedObjectContext *)context;


+(DeviceUser *)bindDeviceUserWithUserID:(NSString *)userId
                 inManagedObjectContext:(NSManagedObjectContext *)context;
@end

NS_ASSUME_NONNULL_END

#import "DeviceUser+CoreDataProperties.h"
