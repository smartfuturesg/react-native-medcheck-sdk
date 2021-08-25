//
//  LSBLEProtocolDelegate.h
//  LifesenseBle
//
//  Created by lifesense on 14-8-1.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

//设备信息写类型，1表示写产品的用户信息（对于A3脂肪秤），2表示写计步器的用户信息，3表示写计步器闹钟信息
typedef enum {
    WriteInfoTypeUnknown=0,
    WRITE_PRODUCT_USER_INFO=1,
    WRITE_PEDOMETER_USER_INFO=2,
    WRITE_ALARM_CLOCK=3,
}WriteInfoType;

#import <Foundation/Foundation.h>
#import "LSDeviceInfo.h"
#import "LSProductUserInfo.h"

@protocol LSProtocolHandleCenterDelegate <NSObject>
@required

//上层管理器的工作状态改变
-(void)bleProtocolDidWorkStatusChange:(NSInteger)workStatus;

//A3设备发现设备用户列表
-(void)bleProtocolDidDiscoverdUserlist:(NSDictionary *)userlist;

//A3脂肪秤，发现设备的用户信息
-(void)bleProtocolDidDiscoverdProductUserInfo:(LSProductUserInfo *)productUserInfo;

//配对结果
-(void)bleProtocolDidPairedResults:(LSDeviceInfo *)pairedLsDevice pairedStatus:(NSInteger)pairedStatus;

//测量数据上传,new change ,返回整个设备对象信息，方便后期的功能扩展
-(void)bleProtocolDidReceiveMeasuredData:(id)measureData fromCharacteristic:(NSInteger)characteristicUuid device:(LSDeviceInfo *)deviceInfo;

//数据上传完成标记
-(void)bleProtocolDidDataReceiveComplete:(NSUInteger)completedFlag deviceId:(NSString *)deviceId;

//用户信息设置成功后的回调
-(void)bleProtocolDidWriteSuccessForUserInfo:(NSString *)deviceId memberId:(NSString *)memberId writeInfoType:(WriteInfoType)writeType;

//发现设备的详细信息，适用于没有配对过程的设备，如通用脂肪秤,厨房秤
-(void)bleProtocolDidDiscoverdDeviceInfo:(LSDeviceInfo *)deviceInfo;

//设备连接状态改变
-(void)bleProtocolDidConnectStatusChange:(DeviceConnectState)connnectState broadcastId:(NSString *)broadcastId;

//version 1.0.8 new change
-(void)bleProtocolDidWaitingForCommandToStartMeasuring:(NSString *)deviceId;



@end
