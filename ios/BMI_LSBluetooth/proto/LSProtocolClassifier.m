//
//  LSProtocolClassifier.m
//  LSBluetooth-Library
//
//  Created by lifesense on 15/7/27.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import "LSProtocolClassifier.h"
#import "LSBleCommandProfiles.h"
#import "LSFormatConverter.h"
#import "BleDebugLogger.h"

@implementation LSProtocolClassifier


+(NSArray *)protocolProcesses:(LSDeviceInfo *)device workingMode:(DeviceWorkingMode)workingMode deviceUserInfo:(NSDictionary *)userInfoMap
{
    if(device)
    {
        NSArray *protocolProcessesQueue=nil;
       
        if(workingMode==PAIRING_DEVICE_MODE)
        {
           //根据设备协议类型、设备类型获取相应的配对协议流程
            protocolProcessesQueue=[self pairingProtocolProcesses:device userInfo:userInfoMap];
        }
        if(workingMode==DATA_UPLOADING_MODE)
        {
            //根据设备协议类型、设备类型获取相应测量数据上传的协议流程
            protocolProcessesQueue=[self uploadingProtocolProcesses:device userInfo:userInfoMap];
        }
    
         return protocolProcessesQueue;
    }
    else return nil;
    
    
}


#pragma mark - data uploading protocol processes

+(NSArray *)uploadingProtocolProcesses:(LSDeviceInfo *)device userInfo:(NSDictionary *)userInfoMap
{
    NSString *protocolType=device.protocolType;
    LSDeviceType deviceType=device.deviceType;
    if([PROTOCOL_TYPE_A2 isEqualToString:protocolType])
    {
        //A2 协议测量数据上传流程
        return [self uploadingProtocolProcessesForA2:deviceType userInfo:userInfoMap];
    }
    else if([PROTOCOL_TYPE_A3 isEqualToString:protocolType])
    {
         //A3 协议测量数据上传流程
        return [self uploadingProtocolProcessesForA3:deviceType userInfo:userInfoMap];
    }
    else if([PROTOCOL_TYPE_A3_1 isEqualToString:protocolType])
    {
         //A3.1 协议测量数据上传流程
        return [self uploadingProtocolProcessesForA3_1:deviceType userInfo:userInfoMap];
    }
   else if ([PROTOCOL_TYPE_GENERIC_FAT isEqualToString:protocolType])
    {
         //通用脂肪秤 协议测量数据上传流程
        return [self uploadingProtocolProcessesForGenericFat:deviceType userInfo:nil];
    }
   else  if([PROTOCOL_TYPE_KITCHEN isEqualToString:protocolType])
    {
         //厨房秤 协议测量数据上传流程
        return [self uploadingProtocolProcessesForKitchenScale:deviceType userInfo:nil];
    }
   else if([PROTOCOL_TYPE_BLOOD_PRESSURE_COMMAND_START isEqualToString:protocolType])
    {
         //命令启动血压计协议测量数据上传流程
        return [self uploadingProtocolProcessesForCommandStart:deviceType userInfo:userInfoMap];
    }
//   else if([PROTOCOL_TYPE_A4 isEqualToString:protocolType])
//   {
//       //命令启动血压计协议测量数据上传流程
//       return [self uploadingProtocolProcessesForA4:deviceType userInfo:userInfoMap];
//   }
    else return nil;
}

//A2 测量数据上传的协议流程
+(NSArray *)uploadingProtocolProcessesForA2:(LSDeviceType)deviceType userInfo:(NSDictionary *)userInfoMap
{
    
    NSMutableArray * msgQueue=[[NSMutableArray alloc] init];
    //connect device
    LSProtocolMessage *connectMsg=[[LSProtocolMessage alloc] init];
    connectMsg.operatingDirective=OPERATING_CONNECT_DEVICE;
    
    //set notify to characteristic
    LSProtocolMessage *setNotifyMsg=[[LSProtocolMessage alloc] init];
    setNotifyMsg.operatingDirective=OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS;
    
    //receive random number
    LSProtocolMessage *receiveRandomMsg=[[LSProtocolMessage alloc] init];
    receiveRandomMsg.operatingDirective=OPERATING_RECEIVE_RANDOM_NUMBER;
    
    //write xor results
    LSProtocolMessage *writeXorResultsMsg=[[LSProtocolMessage alloc] init];
    writeXorResultsMsg.operatingDirective=OPERATING_WRITE_XOR_RESULTS;
    
    //write utc
    LSProtocolMessage *writeUtcMsg=[[LSProtocolMessage alloc] init];
    writeUtcMsg.operatingDirective=OPERATING_WRITE_UTC_TIME;
    writeUtcMsg.commandData=[LSBleCommandProfiles getUtcCommand];
    
    //write disconnect
    LSProtocolMessage *writeDisconnectMsg=[[LSProtocolMessage alloc] init];
    writeDisconnectMsg.operatingDirective=OPERATING_WRITE_DISCONNECT;
    writeDisconnectMsg.commandData=[LSBleCommandProfiles getDisconnectCommand];
    
    //waiting for measuring data upload
    LSProtocolMessage *uploadResultsMsg=[[LSProtocolMessage alloc] init];
    uploadResultsMsg.operatingDirective=OPERATING_UPLOADED_RESULTS_PROCESS;
    
    [msgQueue enqueue:connectMsg];         //step 1,connect device
    [msgQueue enqueue:setNotifyMsg];       //step 2,set notify to characteristic
    [msgQueue enqueue:receiveRandomMsg];   //step 3,receive random number
    [msgQueue enqueue:writeXorResultsMsg]; //step 4,write xor results
    [msgQueue enqueue:writeUtcMsg];        //step 5,write utc
    
    //if need ,write user info to deivce
    if(userInfoMap && [userInfoMap count])
    {
        [self insertDeviceUserInfo:deviceType messageQueue:msgQueue userInfo:userInfoMap];
    }
    
    [msgQueue enqueue:writeDisconnectMsg];  //step 6,write disconnect command
    [msgQueue enqueue:uploadResultsMsg];    //step 7,waiting for measured data
    
    return msgQueue;
}

//A3 测量数据上传的协议流程
+(NSArray *)uploadingProtocolProcessesForA3:(LSDeviceType)deviceType userInfo:(NSDictionary *)userInfoMap
{
    NSMutableArray * msgQueue=[[NSMutableArray alloc] init];
    //connect device
    LSProtocolMessage *connectMsg=[[LSProtocolMessage alloc] init];
    connectMsg.operatingDirective=OPERATING_CONNECT_DEVICE;
    
    //set notify to characteristic
    LSProtocolMessage *setNotifyMsg=[[LSProtocolMessage alloc] init];
    setNotifyMsg.operatingDirective=OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS;
    
    //receive random number
    LSProtocolMessage *receiveRandomMsg=[[LSProtocolMessage alloc] init];
    receiveRandomMsg.operatingDirective=OPERATING_RECEIVE_RANDOM_NUMBER;
    
    //write xor results
    LSProtocolMessage *writeXorResultsMsg=[[LSProtocolMessage alloc] init];
    writeXorResultsMsg.operatingDirective=OPERATING_WRITE_XOR_RESULTS;
    
    //write utc
    LSProtocolMessage *writeUtcMsg=[[LSProtocolMessage alloc] init];
    writeUtcMsg.operatingDirective=OPERATING_WRITE_UTC_TIME;
    writeUtcMsg.commandData=[LSBleCommandProfiles getUtcCommand];
    
    //write disconnect
    LSProtocolMessage *writeDisconnectMsg=[[LSProtocolMessage alloc] init];
    writeDisconnectMsg.operatingDirective=OPERATING_WRITE_DISCONNECT;
    writeDisconnectMsg.commandData=[LSBleCommandProfiles getDisconnectCommand];
    
    //waiting for measuring data upload
    LSProtocolMessage *uploadResultsMsg=[[LSProtocolMessage alloc] init];
    uploadResultsMsg.operatingDirective=OPERATING_UPLOADED_RESULTS_PROCESS;
    
    [msgQueue enqueue:connectMsg];
    [msgQueue enqueue:setNotifyMsg];
    [msgQueue enqueue:receiveRandomMsg];
    [msgQueue enqueue:writeXorResultsMsg];
    
    //if need ,write user info to deivce
    if(userInfoMap && [userInfoMap count])
    {
        [self insertDeviceUserInfo:deviceType messageQueue:msgQueue userInfo:userInfoMap];
    }
    
    //A3 协议设置用户信息在写UTC命令之前
    [msgQueue enqueue:writeUtcMsg];
    
    [msgQueue enqueue:writeDisconnectMsg];
    [msgQueue enqueue:uploadResultsMsg];

    return msgQueue;
}

//A3.1 测量数据上传的协议流程
+(NSArray *)uploadingProtocolProcessesForA3_1:(LSDeviceType)deviceType userInfo:(NSDictionary *)userInfoMap
{
    NSMutableArray * msgQueue=[[NSMutableArray alloc] init];
    //connect device
    LSProtocolMessage *connectMsg=[[LSProtocolMessage alloc] init];
    connectMsg.operatingDirective=OPERATING_CONNECT_DEVICE;
    
    //set notify to characteristic
    LSProtocolMessage *setNotifyMsg=[[LSProtocolMessage alloc] init];
    setNotifyMsg.operatingDirective=OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS;
    
    //receive random number
    LSProtocolMessage *receiveRandomMsg=[[LSProtocolMessage alloc] init];
    receiveRandomMsg.operatingDirective=OPERATING_RECEIVE_RANDOM_NUMBER;
    
    //write xor results
    LSProtocolMessage *writeXorResultsMsg=[[LSProtocolMessage alloc] init];
    writeXorResultsMsg.operatingDirective=OPERATING_WRITE_XOR_RESULTS;
    
    //write broadcast id
    LSProtocolMessage *writeBroadcastIdMsg=[[LSProtocolMessage alloc] init];
    writeBroadcastIdMsg.operatingDirective=OPERATING_WRITE_BROADCAST_ID;
    
    //write utc
    LSProtocolMessage *writeUtcMsg=[[LSProtocolMessage alloc] init];
    writeUtcMsg.operatingDirective=OPERATING_WRITE_UTC_TIME;
    writeUtcMsg.commandData=[LSBleCommandProfiles getUtcCommand];
    
    //write disconnect
    LSProtocolMessage *writeDisconnectMsg=[[LSProtocolMessage alloc] init];
    writeDisconnectMsg.operatingDirective=OPERATING_WRITE_DISCONNECT;
    writeDisconnectMsg.commandData=[LSBleCommandProfiles getDisconnectCommand];
    
    //waiting for measuring data upload
    LSProtocolMessage *uploadResultsMsg=[[LSProtocolMessage alloc] init];
    uploadResultsMsg.operatingDirective=OPERATING_UPLOADED_RESULTS_PROCESS;
    
    [msgQueue enqueue:connectMsg];        //step 1,connect device
    [msgQueue enqueue:setNotifyMsg];      //step 2,set notify to characteristic
    [msgQueue enqueue:receiveRandomMsg];  //step 3,receive random number
    [msgQueue enqueue:writeXorResultsMsg];//step 4,write xor results
    [msgQueue enqueue:writeBroadcastIdMsg];//step 5,write broadcast id
    [msgQueue enqueue:writeUtcMsg];        //step 6,write utc
    
    //if need ,write user info to deivce
    if(userInfoMap && [userInfoMap count])
    {
        [self insertDeviceUserInfo:deviceType messageQueue:msgQueue userInfo:userInfoMap];
    }
    
    [msgQueue enqueue:writeDisconnectMsg]; //step 7,write disconnect
    [msgQueue enqueue:uploadResultsMsg];   //step 8,waiting for measuring data upload
    
    return msgQueue;

}

//通用脂肪秤协议，测量数据上传流程
+(NSArray *)uploadingProtocolProcessesForGenericFat:(LSDeviceType)deviceType userInfo:(NSDictionary *)userInfoMap
{
    NSMutableArray * msgQueue=[[NSMutableArray alloc] init];
    //connect device
    LSProtocolMessage *connectMsg=[[LSProtocolMessage alloc] init];
    connectMsg.operatingDirective=OPERATING_CONNECT_DEVICE;
    
    //read device info
    LSProtocolMessage *readDeviceInfoMsg=[[LSProtocolMessage alloc] init];
    readDeviceInfoMsg.operatingDirective=OPERATING_READ_DEVICE_INFO;

    //set notify to characteristic
    LSProtocolMessage *setNotifyMsg=[[LSProtocolMessage alloc] init];
    setNotifyMsg.operatingDirective=OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS;
    
    //write utc
    LSProtocolMessage *writeUtcMsg=[[LSProtocolMessage alloc] init];
    writeUtcMsg.operatingDirective=OPERATING_WRITE_UTC_TIME;
    writeUtcMsg.commandData=[LSBleCommandProfiles getUtcCommand];
    
    //write disconnect
    LSProtocolMessage *writeDisconnectMsg=[[LSProtocolMessage alloc] init];
    writeDisconnectMsg.operatingDirective=OPERATING_WRITE_DISCONNECT;
    writeDisconnectMsg.commandData=[LSBleCommandProfiles getDisconnectCommand];
    
    //waiting for measuring data upload
    LSProtocolMessage *uploadResultsMsg=[[LSProtocolMessage alloc] init];
    uploadResultsMsg.operatingDirective=OPERATING_UPLOADED_RESULTS_PROCESS;
    
    [msgQueue enqueue:connectMsg];          //step 1,connect device
    [msgQueue enqueue:readDeviceInfoMsg];   //step 2,receive random number
    [msgQueue enqueue:writeUtcMsg];         //step 3,write utc
    [msgQueue enqueue:setNotifyMsg];        //step 4,set notify to characteristic
//    [msgQueue enqueue:writeDisconnectMsg];  //step 5,write disconnect command
    [msgQueue enqueue:uploadResultsMsg];    //step 6,waiting for measured data
    
    return msgQueue;
}

//厨房秤协议，测量数据上传流程
+(NSArray *)uploadingProtocolProcessesForKitchenScale:(LSDeviceType)deviceType userInfo:(NSDictionary *)userInfoMap
{
    NSMutableArray * msgQueue=[[NSMutableArray alloc] init];
    //connect device
    LSProtocolMessage *connectMsg=[[LSProtocolMessage alloc] init];
    connectMsg.operatingDirective=OPERATING_CONNECT_DEVICE;
    
    //read device info
    LSProtocolMessage *readDeviceInfoMsg=[[LSProtocolMessage alloc] init];
    readDeviceInfoMsg.operatingDirective=OPERATING_READ_DEVICE_INFO;
    
    //set notify to characteristic
    LSProtocolMessage *setNotifyMsg=[[LSProtocolMessage alloc] init];
    setNotifyMsg.operatingDirective=OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS;
    
    //waiting for measuring data upload
    LSProtocolMessage *uploadResultsMsg=[[LSProtocolMessage alloc] init];
    uploadResultsMsg.operatingDirective=OPERATING_UPLOADED_RESULTS_PROCESS;
    
    [msgQueue enqueue:connectMsg];          //step 1,connect device
    [msgQueue enqueue:readDeviceInfoMsg];   //step 2,receive random number
    [msgQueue enqueue:setNotifyMsg];        //step 3,set notify to characteristic
    [msgQueue enqueue:uploadResultsMsg];    //step 4,waiting for measured data
    
    return msgQueue;
}

//通过命令启动血压计进行测量协议，测量数据上传流程
+(NSArray *)uploadingProtocolProcessesForCommandStart:(LSDeviceType)deviceType userInfo:(NSDictionary *)userInfoMap
{
    NSMutableArray * msgQueue=[[NSMutableArray alloc] init];
    //connect device
    LSProtocolMessage *connectMsg=[[LSProtocolMessage alloc] init];
    connectMsg.operatingDirective=OPERATING_CONNECT_DEVICE;
    
    //read device info
    LSProtocolMessage *readDeviceInfoMsg=[[LSProtocolMessage alloc] init];
    readDeviceInfoMsg.operatingDirective=OPERATING_READ_DEVICE_INFO;
    
    //set notify to characteristic
    LSProtocolMessage *setNotifyMsg=[[LSProtocolMessage alloc] init];
    setNotifyMsg.operatingDirective=OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS;
    
    //write disconnect
    LSProtocolMessage *writeStartMeasureMsg=[[LSProtocolMessage alloc] init];
    writeStartMeasureMsg.operatingDirective=OPERATING_WRITE_START_MEASURE_COMMAND_TO_DEVICE;
    
    //write utc
    LSProtocolMessage *writeUtcMsg=[[LSProtocolMessage alloc] init];
    writeUtcMsg.operatingDirective=OPERATING_WRITE_UTC_TIME;
    writeUtcMsg.commandData=[LSBleCommandProfiles getUtcCommand];
    
    //waiting for measuring data upload
    LSProtocolMessage *uploadResultsMsg=[[LSProtocolMessage alloc] init];
    uploadResultsMsg.operatingDirective=OPERATING_UPLOADED_RESULTS_PROCESS;
    
    [msgQueue enqueue:connectMsg];            //step 1,connect device
    [msgQueue enqueue:setNotifyMsg];          //step 2,set notify to characteristic
    [msgQueue enqueue:writeStartMeasureMsg];  //step 3,write disconnect command
    [msgQueue enqueue:writeUtcMsg];           //step 4,write utc
    [msgQueue enqueue:uploadResultsMsg];      //step 5,waiting for measured data
    
    return msgQueue;
}


//A4手环，测量数据上传流程
+(NSArray *)uploadingProtocolProcessesForA4:(LSDeviceType)deviceType userInfo:(NSDictionary *)userInfoMap
{
    NSMutableArray * msgQueue=[[NSMutableArray alloc] init];
    //connect device
    LSProtocolMessage *connectMsg=[[LSProtocolMessage alloc] init];
    connectMsg.operatingDirective=OPERATING_CONNECT_DEVICE;
    
    //read device info
    LSProtocolMessage *readDeviceInfoMsg=[[LSProtocolMessage alloc] init];
    readDeviceInfoMsg.operatingDirective=OPERATING_READ_DEVICE_INFO;
    
    //set notify to characteristic
    LSProtocolMessage *setNotifyMsg=[[LSProtocolMessage alloc] init];
    setNotifyMsg.operatingDirective=OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS;
    
    //write auth response
    LSProtocolMessage *writeAuthResponseMsg=[[LSProtocolMessage alloc] init];
    writeAuthResponseMsg.operatingDirective=OPERATING_WRITE_AUTH_RESPONSE;
    
    //write init response
    LSProtocolMessage *writeInitResponseMsg=[[LSProtocolMessage alloc] init];
    writeInitResponseMsg.operatingDirective=OPERATING_WRITE_INIT_RESPONSE;
  
    //waiting for measuring data upload
    LSProtocolMessage *receiveDataMsg=[[LSProtocolMessage alloc] init];
    receiveDataMsg.operatingDirective=OPERATING_WAITING_TO_RECEIVE_DATA;
    
    [msgQueue enqueue:connectMsg];            //step 1,connect device
    [msgQueue enqueue:readDeviceInfoMsg];     //step 2,read device info
    [msgQueue enqueue:setNotifyMsg];          //step 3,set notify to characteristic
    [msgQueue enqueue:writeAuthResponseMsg];  //step 4,write auto response command
    [msgQueue enqueue:writeInitResponseMsg]; //step 5,write init response command
    [msgQueue enqueue:receiveDataMsg];      //step 6,waiting for receive command request data
    
    return msgQueue;
}


#pragma mark - pairing protocol processes

+(NSArray *)pairingProtocolProcesses:(LSDeviceInfo *)device userInfo:(NSDictionary *)userInfoMap
{
     NSString *protocolType=device.protocolType;
     LSDeviceType deviceType=device.deviceType;
    if([PROTOCOL_TYPE_A2 isEqualToString:protocolType])
    {
        //A2 协议配对流程
        return [self pairingProtocolProcessesForA2:deviceType userInfo:userInfoMap];
    }
    else if([PROTOCOL_TYPE_A3 isEqualToString:protocolType] || [PROTOCOL_TYPE_A3_1 isEqualToString:protocolType])
    {
        return [self pairingProtocolProcessesForA3:deviceType userInfo:userInfoMap];
    }
  
    else return nil;
    
}

//A2 协议配对流程
+(NSArray *)pairingProtocolProcessesForA2:(LSDeviceType)deviceType userInfo:(NSDictionary *)userInfoMap
{
    
    NSMutableArray * msgQueue=[[NSMutableArray alloc] init];
   
    //connect device
    LSProtocolMessage *connectMsg=[[LSProtocolMessage alloc] init];
    connectMsg.operatingDirective=OPERATING_CONNECT_DEVICE;
    
    //read device info
    LSProtocolMessage *readDeviceInfoMsg=[[LSProtocolMessage alloc] init];
    readDeviceInfoMsg.operatingDirective=OPERATING_READ_DEVICE_INFO;
    
    //set notify to characteristic
    LSProtocolMessage *setNotifyMsg=[[LSProtocolMessage alloc] init];
    setNotifyMsg.operatingDirective=OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS;
    
    //receive password
    LSProtocolMessage *receivePasswordMsg=[[LSProtocolMessage alloc] init];
    receivePasswordMsg.operatingDirective=OPERATING_RECEIVE_PASSWORD;
    
    //write broadcast id
    LSProtocolMessage *writeBroadcastIdMsg=[[LSProtocolMessage alloc] init];
    writeBroadcastIdMsg.operatingDirective=OPERATING_WRITE_BROADCAST_ID;
    
    //receive random number
    LSProtocolMessage *receiveRandomMsg=[[LSProtocolMessage alloc] init];
    receiveRandomMsg.operatingDirective=OPERATING_RECEIVE_RANDOM_NUMBER;
    
    //write xor results
    LSProtocolMessage *writeXorResultsMsg=[[LSProtocolMessage alloc] init];
    writeXorResultsMsg.operatingDirective=OPERATING_WRITE_XOR_RESULTS;
    
    //write utc
    LSProtocolMessage *writeUtcMsg=[[LSProtocolMessage alloc] init];
    writeUtcMsg.operatingDirective=OPERATING_WRITE_UTC_TIME;
    writeUtcMsg.commandData=[LSBleCommandProfiles getUtcCommand];
    
    //write disconnect
    LSProtocolMessage *writeDisconnectMsg=[[LSProtocolMessage alloc] init];
    writeDisconnectMsg.operatingDirective=OPERATING_WRITE_DISCONNECT;
    writeDisconnectMsg.commandData=[LSBleCommandProfiles getDisconnectCommand];
    
    //waiting for return paired results
    LSProtocolMessage *pairedResultsMsg=[[LSProtocolMessage alloc] init];
    pairedResultsMsg.operatingDirective=OPERATING_PAIRED_RESULTS_PROCESS;
    

    [msgQueue enqueue:connectMsg];          //step 1,connect device
    [msgQueue enqueue:readDeviceInfoMsg];   //step 2,read device info
    [msgQueue enqueue:setNotifyMsg];        //step 3,set notify to characteristic
    [msgQueue enqueue:receivePasswordMsg];  //step 4,receive password
    [msgQueue enqueue:writeBroadcastIdMsg]; //step 5,write broadcast id
    [msgQueue enqueue:receiveRandomMsg];    //step 6,receive random number
    [msgQueue enqueue:writeXorResultsMsg];  //step 7,write xor results
    [msgQueue enqueue:writeUtcMsg];         //step 8,write utc
    
    //A2配对协议流程，写设备用户信息在写UTC之后
    //if need ,write user info to deivce
    if(userInfoMap && userInfoMap.count)
    {
        [self insertDeviceUserInfo:deviceType messageQueue:msgQueue userInfo:userInfoMap];
    }
    [msgQueue enqueue:writeDisconnectMsg];   //step 9,write disconnect
    [msgQueue enqueue:pairedResultsMsg];    //step 10,waiting for measuring data upload
    
    return msgQueue;
 
}

//A3 协议配对流程
+(NSArray *)pairingProtocolProcessesForA3:(LSDeviceType)deviceType userInfo:(NSDictionary *)userInfoMap
{

    
    NSMutableArray * msgQueue=[[NSMutableArray alloc] init];
    
    //connect device
    LSProtocolMessage *connectMsg=[[LSProtocolMessage alloc] init];
    connectMsg.operatingDirective=OPERATING_CONNECT_DEVICE;
    
    //read device info
    LSProtocolMessage *readDeviceInfoMsg=[[LSProtocolMessage alloc] init];
    readDeviceInfoMsg.operatingDirective=OPERATING_READ_DEVICE_INFO;
    
    //set notify to characteristic
    LSProtocolMessage *setNotifyMsg=[[LSProtocolMessage alloc] init];
    setNotifyMsg.operatingDirective=OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS;
    
    //receive password
    LSProtocolMessage *receivePasswordMsg=[[LSProtocolMessage alloc] init];
    receivePasswordMsg.operatingDirective=OPERATING_RECEIVE_PASSWORD;
    
    //write broadcast id
    LSProtocolMessage *writeBroadcastIdMsg=[[LSProtocolMessage alloc] init];
    writeBroadcastIdMsg.operatingDirective=OPERATING_WRITE_BROADCAST_ID;
 
    
    //receive random number
    LSProtocolMessage *receiveRandomMsg=[[LSProtocolMessage alloc] init];
    receiveRandomMsg.operatingDirective=OPERATING_RECEIVE_RANDOM_NUMBER;
    
    //write xor results
    LSProtocolMessage *writeXorResultsMsg=[[LSProtocolMessage alloc] init];
    writeXorResultsMsg.operatingDirective=OPERATING_WRITE_XOR_RESULTS;
    
    //bind device user
    LSProtocolMessage *bindDeviceUserMsg=[[LSProtocolMessage alloc] init];
    bindDeviceUserMsg.operatingDirective=OPERATING_WRITE_BIND_USER_NUMBER;
    
    //write utc
    LSProtocolMessage *writeUtcMsg=[[LSProtocolMessage alloc] init];
    writeUtcMsg.operatingDirective=OPERATING_WRITE_UTC_TIME;
    writeUtcMsg.commandData=[LSBleCommandProfiles getUtcCommand];
    
    //write disconnect
    LSProtocolMessage *writeDisconnectMsg=[[LSProtocolMessage alloc] init];
    writeDisconnectMsg.operatingDirective=OPERATING_WRITE_DISCONNECT;
    writeDisconnectMsg.commandData=[LSBleCommandProfiles getDisconnectCommand];
    
    //waiting for return paired results
    LSProtocolMessage *pairedResultsMsg=[[LSProtocolMessage alloc] init];
    pairedResultsMsg.operatingDirective=OPERATING_PAIRED_RESULTS_PROCESS;
    
    
    [msgQueue enqueue:connectMsg];          //step 1,connect device
    [msgQueue enqueue:readDeviceInfoMsg];   //step 2,read device info
    [msgQueue enqueue:setNotifyMsg];        //step 3,set notify to characteristic
    [msgQueue enqueue:receivePasswordMsg];  //step 4,receive password
    [msgQueue enqueue:writeBroadcastIdMsg]; //step 5,write broadcast id
    [msgQueue enqueue:receiveRandomMsg];    //step 6,receive random number
    [msgQueue enqueue:writeXorResultsMsg];  //step 7,write xor results
    [msgQueue enqueue:bindDeviceUserMsg];   //step 8,bind device user
    
    //A3配对协议流程，写设备用户信息在写UTC之前
    //if need ,write user info to deivce
    
    [self insertDeviceUserInfo:deviceType messageQueue:msgQueue userInfo:userInfoMap];
  
    [msgQueue enqueue:writeUtcMsg];         //step 9,write utc
    
    [msgQueue enqueue:writeDisconnectMsg];   //step 10,write disconnect
    [msgQueue enqueue:pairedResultsMsg];    //step 11,waiting for measuring data upload
    
    return msgQueue;
    
}


#pragma mark - set device user info

+(void)debugMessage:(NSString *)msg debuglevel:(DebugLevel)level
{
    [BleDebugLogger object:self printMessage:msg withDebugLevel:level];
}

//根据设备类型，插入设备的用户信息
+(void)insertDeviceUserInfo:(LSDeviceType)deviceType messageQueue:(NSMutableArray*)messageQueue userInfo:(NSDictionary *)userInfoMap
{
    NSString *userInfoMsg=nil;
    if(deviceType==LS_FAT_SCALE)
    {
        LSProtocolMessage *writeUserInfoMsg=[[LSProtocolMessage alloc] init];
        writeUserInfoMsg.operatingDirective=OPERATING_WRITE_USER_INFO;
       
        
        //A3协议脂肪秤支持写用户信息
        id userInfo=[userInfoMap objectForKey:KEY_WEIGHT_SCALE_USER_INFO];
        if (userInfo && [userInfo isKindOfClass:[LSProductUserInfo class]])
        {
            LSProductUserInfo *weightUserInfo=(LSProductUserInfo *)userInfo;
             writeUserInfoMsg.commandData=[weightUserInfo userInfoCommandData];
            
            userInfoMsg=[NSString stringWithFormat:@"set custom product user info-%@",[LSFormatConverter dictionaryWithProperty:weightUserInfo]];
            [self debugMessage:userInfoMsg debuglevel:DEBUG_LEVEL_SUPREME];
        }
        else
        {
            [self debugMessage:@"no custom product user info...." debuglevel:DEBUG_LEVEL_GENERAL];
            writeUserInfoMsg.commandData=nil;
        }
        
        [messageQueue enqueue:writeUserInfoMsg];
    }
    else if (deviceType==LS_PEDOMETER)
    {
        //A2协议手环支持写手环的用户信息
        id tempUserInfo=[userInfoMap objectForKey:KEY_PEDOMETER_USER_INFO];
        if(tempUserInfo &&[tempUserInfo isKindOfClass:[LSPedometerUserInfo class]])
        {
            LSPedometerUserInfo *peUserInfo=(LSPedometerUserInfo*)tempUserInfo;
            [self initPedometerUserInfoSetting:peUserInfo messageQueue:messageQueue];
            
            userInfoMsg=[NSString stringWithFormat:@"set custom pedometer user info-%@",[LSFormatConverter dictionaryWithProperty:peUserInfo]];
            [self debugMessage:userInfoMsg debuglevel:DEBUG_LEVEL_SUPREME];
            
        }
         id alarmClock=[userInfoMap objectForKey:KEY_PEDOMETER_ALARM_CLOCK];
        if(alarmClock && [alarmClock isKindOfClass:[LSPedometerAlarmClock class]])
        {
            LSPedometerAlarmClock *alarmClockInfo=(LSPedometerAlarmClock *)alarmClock;
            
            LSProtocolMessage *writeAlarmClockMsg=[[LSProtocolMessage alloc] init];
            writeAlarmClockMsg.operatingDirective=OPERATING_WRITE_ALARM_CLOCK;
            writeAlarmClockMsg.commandData=[alarmClockInfo getData];
            
            [messageQueue enqueue:writeAlarmClockMsg];
            
            userInfoMsg=[NSString stringWithFormat:@"set custom pedometer alarm clock-%@",[LSFormatConverter dictionaryWithProperty:alarmClockInfo]];
            [self debugMessage:userInfoMsg debuglevel:DEBUG_LEVEL_SUPREME];
        }
  
    }
    else if(deviceType==LS_WEIGHT_SCALE)
    {
        //木头秤（baby scale）支持写声音振动提示功能
        id userInfo=[userInfoMap objectForKey:KEY_WEIGHT_SCALE_VIBRATION_VOICE];
        if( userInfo && [userInfo isKindOfClass:[LSVibrationVoice class]])
        {
            LSVibrationVoice *vibrationVoiceInfo=(LSVibrationVoice *)userInfo;
            
            LSProtocolMessage *writeVoiceMsg=[[LSProtocolMessage alloc] init];
            writeVoiceMsg.operatingDirective=OPERATING_WRITE_VIBRATION_VOICE;
            writeVoiceMsg.commandData=[vibrationVoiceInfo getCommandDataBytes];
            
            [messageQueue enqueue:writeVoiceMsg];
            
            userInfoMsg=[NSString stringWithFormat:@"set custom vibration voice info-%@",[LSFormatConverter dictionaryWithProperty:vibrationVoiceInfo]];
            [self debugMessage:userInfoMsg debuglevel:DEBUG_LEVEL_SUPREME];

        }
    }
}

/*
 * 设置手环的当前状态、星期开始时间、周目标等信息
 */
+(void)initPedometerUserInfoSetting:(LSPedometerUserInfo *)peUserInfo messageQueue:(NSMutableArray *)peUserInfoQueue
{
    if(peUserInfo)
    {
        if([peUserInfo isUserMessageSetting])
        {
            LSProtocolMessage *userMessage=[[LSProtocolMessage alloc] init];
            userMessage.operatingDirective=OPERATING_WRITE_USER_MESSAGE_TO_PEDOMETER;
            userMessage.commandData=peUserInfo.userMessageCommandData;
            [peUserInfoQueue enqueue:userMessage];
        }
        if([peUserInfo isCurrentStateSetting])
        {
            LSProtocolMessage *currentState=[[LSProtocolMessage alloc] init];
            currentState.operatingDirective=OPERATING_WRITE_CURRENT_STATE_TO_PEDOMETER;
            currentState.commandData=peUserInfo.currentStateCommandData;
            [peUserInfoQueue enqueue:currentState];
            
        }
        if([peUserInfo isWeekStartSetting])
        {
            LSProtocolMessage *weekTargetMessage=[[LSProtocolMessage alloc] init];
            weekTargetMessage.operatingDirective=OPERATING_WRITE_TARGET_STATE_TO_PEDOMETER;
            weekTargetMessage.commandData=peUserInfo.weekTargetCommandData;
            [peUserInfoQueue enqueue:weekTargetMessage];
            
        }
        if([peUserInfo isUnitConversionSetting])
        {
            LSProtocolMessage *unitConversionMessage=[[LSProtocolMessage alloc] init];
            unitConversionMessage.operatingDirective=OPERATING_WRITE_UNIT_CONVERSION_TO_PEDOMETER;
            unitConversionMessage.commandData=peUserInfo.unitConversionCommandData;
            [peUserInfoQueue enqueue:unitConversionMessage];
        }
        
    }
}


@end
