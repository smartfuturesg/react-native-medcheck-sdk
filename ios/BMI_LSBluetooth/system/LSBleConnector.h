//
//  LSBLEConnector.h
//  LifesenseBle
//
//  Created by lifesense on 14-8-1.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CBCharacteristic.h>
#import <CoreBluetooth/CBPeripheral.h>
#import "LSBleConnectorDelegate.h"
#import "LSFormatConverter.h"
#import "LSBleStatusChangeDelegate.h"

@interface LSBleConnector : NSObject

@property(nonatomic,assign)id<LSBleConnectorDelegate> bleConnectorDelegate;
@property(nonatomic,readonly)BOOL isScanning;
@property(nonatomic,strong)dispatch_queue_t dispatchQueue;



-(void)checkBluetoothStatus:(id<LSBleStatusChangeDelegate>)bleStateDelegate;

-(BOOL)scanWithServices:(NSArray *)services;

-(void)stopScan;

-(void)connectPeripheral:(CBPeripheral *)lsPeripheral;

-(void)disConnectPeripheral;

-(void)discoverCharacteristicsForService:(CBService *)service;

-(void)readValueForCharacteristic:(CBCharacteristic *)characteristic;

-(void)setNotifyValue:(BOOL)notifyFlags forCharacteristic:(CBCharacteristic *)lsCharacteristic;

-(void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)downloadCharacteristic;

@end
