//
//  ProtocolHandleCenter.h
//  LSBluetooth-Library
//
//  Created by lifesense on 15/8/5.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CBPeripheral.h>
#import <CoreBluetooth/CBService.h>
#import "BleManagerProfiles.h"
#import "LSBleGattServicesConstants.h"
#import "BleDebugLogger.h"
#import "LSFormatConverter.h"
#import "LSBleConnector.h"
#import "LSProtocolHandleCenterDelegate.h"
#import "LSBleDataParsingTools.h"
#import "LSPedometerAlarmClock.h"
#import "NSMutableArray+QueueAdditions.h"
#import "LSProtocolMessage.h"

typedef enum{
    ProcessorWorkingStatusFree,
    ProcessorWorkingStatusPairing,
    ProcessorWorkingStatusUploading,
}ProcessorWorkingStatus;

@interface LSProtocolHandleCenter : NSObject

@property(nonatomic,strong)id<LSProtocolHandleCenterDelegate> bleProtocolDelegate;
@property(nonatomic,strong)LSPedometerAlarmClock *alarmClock;
@property(nonatomic,strong)LSPedometerUserInfo *pedometerUserInfo;
@property(nonatomic,strong)LSProductUserInfo *localProductUserInfo;
@property(nonatomic,strong)LSVibrationVoice *vibrationVoice;
@property(nonatomic,strong)LSBleConnector *bleConnector;


//执行配对协议流程
-(void)pairingWithDevice:(LSDeviceInfo *)pairingDevice peripheral:(CBPeripheral *)peripheral protocolProcesses:(NSArray *)pairingProtocolQueue count:(NSUInteger)connectCount;


//执行测量数据上传协议流程
-(void)uploadingWithDevice:(LSDeviceInfo *)pairedDevice peripheral:(CBPeripheral *)peripheral protocolProcesses:(NSArray *)uploadingProtocolQueue count:(NSUInteger)connectCount;


//中断正在执行的任务
-(void)interruptCurrentTask;

//绑定用户编号,A3、A3.1协议专用
-(void)bindingDeviceUsers:(NSUInteger)userNumber userName:(NSString *)name;

//版本1.0.8新增接口，写UTC启动测量
-(BOOL)writeCommandToStartMeasuring;


@end
