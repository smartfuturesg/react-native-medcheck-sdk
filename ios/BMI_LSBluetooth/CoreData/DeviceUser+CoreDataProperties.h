//
//  DeviceUser+CoreDataProperties.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "DeviceUser+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface DeviceUser (CoreDataProperties)

+ (NSFetchRequest<DeviceUser *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *athleteLevel;
@property (nullable, nonatomic, copy) NSDate *birthday;
@property (nullable, nonatomic, copy) NSString *gender;
@property (nullable, nonatomic, copy) NSNumber *height;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *userID;
@property (nullable, nonatomic, copy) NSNumber *weight;
@property (nullable, nonatomic, retain) NSSet<BleDevice *> *devices;
@property (nullable, nonatomic, retain) DeviceUserProfiles *userprofiles;

@end

@interface DeviceUser (CoreDataGeneratedAccessors)

- (void)addDevicesObject:(BleDevice *)value;
- (void)removeDevicesObject:(BleDevice *)value;
- (void)addDevices:(NSSet<BleDevice *> *)values;
- (void)removeDevices:(NSSet<BleDevice *> *)values;

@end

NS_ASSUME_NONNULL_END
