//
//  LSProtocolWorkflow.h
//  LSBluetooth-Library
//
//  Created by lifesense on 15/8/5.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OPERATING_UNKNOWN,
    OPERATING_FREE,								//空闲状态
    OPERATING_CONNECT_DEVICE,					//连接设备
    OPERATING_READ_DEVICE_INFO,					//读取设备信息
    OPERATING_RECEIVE_PASSWORD,					//接收密码
    OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS,	//打开特征通道
    OPERATING_SET_NOTIFY_FOR_DESCRIPTOR,		//血糖仪的特征通道
    
    OPERATING_WRITE_BROADCAST_ID,				//写广播ID
    OPERATING_RECEIVE_RANDOM_NUMBER,			//接收随机数
    OPERATING_WRITE_XOR_RESULTS,				//写异或结果到设备
    OPERATING_WRITE_BIND_USER_NUMBER,			//写绑定用户编号，A3协议
    OPERATING_WRITE_UNBIND_USER_NUMBER,			//写解除绑定命令到设备
    OPERATING_WRITE_USER_INFO,					//写设备信息
    OPERATING_WRITE_ALARM_CLOCK,				//写计步器的闹钟信息
    OPERATING_WRITE_UTC_TIME,					//写utc时间
    OPERATING_WRITE_DISCONNECT,					//写允许断开命令
    OPERATING_PAIRED_RESULTS_PROCESS,			//配对结果处理
    OPERATING_UPLOADED_RESULTS_PROCESS,			//测量数据上传完成处理
    
    OPERATING_SET_INDICATE_FOR_CHARACTERISTICS, //打开A4设备的特征通道
    OPERATING_WRITE_AUTH_RESPONSE,			    //写登录回复命令
    OPERATING_WRITE_INIT_RESPONSE,				//写初始化回复命令
    OPERATING_WAITING_TO_RECEIVE_DATA,          //等待接收测量数据的上传
    OPERATING_WRITE_C7_COMMAND_TO_DEVICE,		//回复计步器下载信息命令
    OPERATING_WRITE_C4_COMMAND_TO_DEVICE,		//回复接收计步器测量数据命令
    OPERATING_WRITE_C9_COMMAND_TO_DEVICE,       //回复接收计步器详细测量数据的命令
    OPERATING_WRITE_CA_COMMAND_TO_DEVICE,		//回复接收计步器每天的测量数据结果
    OPERATING_WRITE_CB_COMMAND_TO_DEVICE,		//回复接收计步器push用户信息确认结果
    OPERATING_WRITE_CE_COMMAND_TO_DEVICE,		//回复接收计步器push睡眠数据确认信息
    OPERATING_WRITE_CC_COMMAND_TO_DEVICE,		//回复接收A4体重秤的设备信息命令
    OPERATING_WRITE_C3_COMMAND_TO_DEVICE,		//回复接收A4体重秤的测量数据命令
    
    OPERATING_WRITE_VIBRATION_VOICE,			//设置设备的振动提示声音
    OPERATING_WRITE_CURRENT_STATE_FOR_PEDOMETER_A2,	//设置A2手环的当前状态，包括时间显示系统的制度，长度单位
    
    //v3.3.0新增支持厨房秤协议
    OPERATING_SET_NOTIFY_FOR_KITCHEN_SCALE,		//厨房秤的特征通道
    
    //v3.3.2
    OPERATING_WRITE_START_MEASURE_COMMAND_TO_DEVICE,
    
    //new change for version 3.3.7
    OPERATING_WRITE_USER_MESSAGE_TO_PEDOMETER,
    OPERATING_WRITE_CURRENT_STATE_TO_PEDOMETER,
    OPERATING_WRITE_TARGET_STATE_TO_PEDOMETER,
    OPERATING_WRITE_UNIT_CONVERSION_TO_PEDOMETER,
    
    
}ProtocolWorkflow;


@interface LSProtocolWorkflow : NSObject

+(NSString *)enumToString:(ProtocolWorkflow)enumValue;

@end
