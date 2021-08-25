//
//  BleDevice+CoreDataProperties.h
//  BPTracker
//
//  Created by LN-MCBK-004 on 11/07/18.
//  Copyright © 2018 Lets Nurture. All rights reserved.
//
//

#import "BleDevice+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface BleDevice (CoreDataProperties)

+ (NSFetchRequest<BleDevice *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *broadcastID;
@property (nullable, nonatomic, copy) NSString *deviceID;
@property (nullable, nonatomic, copy) NSString *deviceName;
@property (nullable, nonatomic, copy) NSString *deviceSN;
@property (nullable, nonatomic, copy) NSString *deviceType;
@property (nullable, nonatomic, copy) NSNumber *deviceUserNumber;
@property (nullable, nonatomic, copy) NSString *firmwareVersion;
@property (nullable, nonatomic, copy) NSString *hardwareVersion;
@property (nullable, nonatomic, copy) NSString *identifier;
@property (nullable, nonatomic, copy) NSString *modelNumber;
@property (nullable, nonatomic, copy) NSString *password;
@property (nullable, nonatomic, copy) NSString *protocolType;
@property (nullable, nonatomic, copy) NSString *softwareVersion;
@property (nullable, nonatomic, copy) NSString *userId;
@property (nullable, nonatomic, retain) DeviceUser *whoBind;

@end

NS_ASSUME_NONNULL_END
