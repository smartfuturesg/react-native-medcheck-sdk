//
//  LSProtocolClassifier.h
//  LSBluetooth-Library
//
//  Created by lifesense on 15/7/27.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//
typedef enum
{
    PAIRING_DEVICE_MODE,
    DATA_UPLOADING_MODE,
    
}DeviceWorkingMode;


//设备用户信息设置类型
/*
typedef enum {
    
    WEIGHT_USER_MESSAGE=0X51,           //体重秤用户基本信息，相应命令为0x51
    WEIGHT_VIBRATION_VOICE=0X54,        //木头秤声音振动提示信息，相应命令为0x54
    PEDOMETER_USER_MESSAGE=0X04,        //手环用户基本信息，相应命令为0x04
    PEDOMETER_CURRENT_STATE=0X05,       //手环当前状态信息，相应命令为0x05
    PEDOMETER_WEEK_TARGET_STATE=0X07,   //手环周目标状态，相应命令为0x07
    PEDOMETER_ALARM_CLOCK=0X42,         //手环闹钟功能，相应命令为0x42
    
    
}DeviceUserInfoType;
*/
#import <Foundation/Foundation.h>
#import "NSMutableArray+QueueAdditions.h"
#import "LSDeviceInfo.h"
#import "LSProtocolMessage.h"
#import "LSProtocolWorkflow.h"
#import "LSProductUserInfo.h"
#import "LSPedometerUserInfo.h"
#import "LSPedometerAlarmClock.h"
#import "LSDeviceProfiles.h"
#import "LSVibrationVoice.h"

@interface LSProtocolClassifier : NSObject

/*
 * 根据当前连接的设备信息、设备用户信息获取当前工作模式所对应的协议流程，让协议处理中心，根据协议流程执行相关操作
 */
+(NSArray *)protocolProcesses:(LSDeviceInfo *)device workingMode:(DeviceWorkingMode)workingMode deviceUserInfo:(NSDictionary *)userInfoMap;

@end
