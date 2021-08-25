//
//  LSBLEDeviceManager.m
//  LifesenseBle
//
//  Created by lifesense on 14-8-1.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

//BleManager current Operating Mode



#import "LSBLEDeviceManager.h"
#import <CoreBluetooth/CBCentralManager.h>
#import "LSBLEConnectorDelegate.h"
#import "LSBleConnector.h"
#import "BleDebugLogger.h"
#import "LSProtocolHandleCenterDelegate.h"
#import "LSFatParser.h"
#import "NSMutableArray+QueueAdditions.h"
#import "LSProtocolMessage.h"
#import "LSProtocolWorkflow.h"
#import "LSProtocolClassifier.h"
#import "LSProtocolHandleCenter.h"
#import "LSDeviceProfiles.h"
#import "DispatchBasedTimer.h"



@interface LSBLEDeviceManager()<LSBleConnectorDelegate,LSProtocolHandleCenterDelegate,LSBleStatusChangeDelegate>

@property(nonatomic,strong)NSMutableArray *enableScanDeviceType;
@property(nonatomic,strong)NSArray *enableScanServices;
@property(nonatomic,strong)LSBleConnector *bleConnector;
@property(nonatomic)NSInteger currentWorkStatus;
@property(nonatomic)NSInteger currentBleStatus;
@property(nonatomic,strong)NSArray *lsDeviceTypeRange;
@property(nonatomic,strong)NSMutableDictionary *lsPeripheralMap;
@property(nonatomic,strong)NSMutableDictionary *enableMeasureDeviceMap;

@property(nonatomic,copy)void(^searchCompletionBlock)(LSDeviceInfo *lsDevice);
@property(nonatomic,copy)void(^checkBleStatusCompletionBlock)(BOOL isSupportFlags,BOOL isOpenFlags);

@property(nonatomic)BroadcastType currentBroadcastType;
@property(nonatomic)BOOL isDataReceiveServiceStart;
@property(nonatomic,strong)id<LSBlePairingDelegate>pairedDelegate;
@property(nonatomic,strong)id<LSBleDataReceiveDelegate>dataReceiveDelegate;
@property(nonatomic)BOOL bleStatusChangeFlag;
@property(nonatomic)BOOL enableSpecialConditions;
@property(nonatomic,strong)NSArray *enableScanBroadcastNames;

@property(nonatomic,strong)LSWeightData *tempWeightData;

//version 1.0.8 new change
@property(nonatomic,strong)id<LSDeviceConnectDelegate> deviceConnectDelegate;
@property(nonatomic,strong)NSString *mCustomBroadacstID;
@property(nonatomic,strong)NSString *mDeviceName;
@property(nonatomic,strong)NSArray *mDeviceTypes;

@property(nonatomic,strong)LSProtocolHandleCenter *protocolHandleCenter;

//device user info setting
@property(nonatomic,strong)NSMutableDictionary *pedometerAlarmClockMap;
@property(nonatomic,strong)NSMutableDictionary *pedometerUserInfoMap;
@property(nonatomic,strong)NSMutableDictionary *vibrationVoiceMap;
@property(nonatomic,strong)NSMutableDictionary *productUserInfoMap;

//
//@property(nonatomic,strong)NSTimer *restartScanTimer;
@property(nonatomic,strong)DispatchBasedTimer *restartScanTimer;
@property(nonatomic)BOOL disableStartDataReceive;

@property(nonatomic,strong,readwrite)NSString *versionName;
@end

@implementation LSBLEDeviceManager

NSString *const CURRENT_VERSION_NAME=@"V3.1.2 build2";


-(instancetype)init
{
    if (self=[super init])
    {
        self.versionName=CURRENT_VERSION_NAME;
        
        //执行其他对象实例的初始化操作
        self.isBluetoothPowerOn=NO;
        self.enableSpecialConditions=NO;
        self.currentWorkStatus=MANAGER_WORK_STATUS_IBLE;
        self.currentBleStatus=CBCentralManagerStateUnknown;
        self.enableScanServices=nil;
        
        
        self.isDataReceiveServiceStart=NO;
        self.bleStatusChangeFlag=NO;
        self.currentBroadcastType=BROADCAST_TYPE_ALL;//default broadcast type
        self.enableScanDeviceType=[[NSMutableArray alloc] init];
        self.enableMeasureDeviceMap=[[NSMutableDictionary alloc] init];
        
        self.pedometerUserInfoMap=[[NSMutableDictionary alloc] init];
        self.productUserInfoMap=[[NSMutableDictionary alloc] init];
        self.vibrationVoiceMap=[[NSMutableDictionary alloc] init];
        self.pedometerAlarmClockMap=[[NSMutableDictionary alloc] init];
        
        self.bleConnector=[[LSBleConnector alloc] init];
        [self.bleConnector checkBluetoothStatus:self];
        
        self.protocolHandleCenter=[[LSProtocolHandleCenter alloc] init];
        self.protocolHandleCenter.bleConnector=self.bleConnector;
        
    }
    return self;
}

#pragma mark - public api

/*
 *  获取默认的蓝牙处理对象
 */
+(instancetype)defaultLsBleManager
{
    static LSBLEDeviceManager *defaultCenter=nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate,^{
        defaultCenter=[[LSBLEDeviceManager alloc] init];
    });
    return defaultCenter;
}

//设置CBCentralManager 运行的调度队列
-(void)setDispatchQueue:(dispatch_queue_t)dispatchQueue
{
    self.bleConnector.dispatchQueue = dispatchQueue;
}
/*
 *  终端蓝牙状态检测
 */
-(void)checkBluetoothStatus:(void(^)(BOOL isSupportFlags,BOOL isOpenFlags))checkCompletion
{
    if(checkCompletion)
    {
        self.checkBleStatusCompletionBlock=checkCompletion;
        [self.bleConnector checkBluetoothStatus:self];
    }
}

//设置计步器的用户信息
-(BOOL)setPedometerUserInfo:(LSPedometerUserInfo *)pedometerUserInfo
{
    if(pedometerUserInfo && self.pedometerUserInfoMap)
    {
        //配对流程，下写用户信息，deviceId为空
        if(pedometerUserInfo.deviceId.length==0)
        {
            [self.protocolHandleCenter setPedometerUserInfo:pedometerUserInfo];
            return YES;
        }
        else
        {
            NSString *pedometerUserInfoKey=[pedometerUserInfo.deviceId uppercaseString];
            if(![self.pedometerUserInfoMap objectForKey:pedometerUserInfoKey])
            {
                //测量数据上传流程，写用户信息，deviceid不为空
                [self.pedometerUserInfoMap setObject:pedometerUserInfo forKey:pedometerUserInfoKey];
                return YES;
            }
            else
            {
                //重复添加同一个设备用户信息对象
                [self.pedometerUserInfoMap removeObjectForKey:pedometerUserInfoKey];
                [self.pedometerUserInfoMap setObject:pedometerUserInfo forKey:pedometerUserInfoKey];
                return YES;
            }
        }
    }
    else
    {
        NSString *msg=[NSString stringWithFormat:@"Failed to set pedometer user info...%@",[LSFormatConverter dictionaryWithProperty:pedometerUserInfo]];
        [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
    
}

//设置计步器的闹钟信息
-(BOOL)setPedometerAlarmClock:(LSPedometerAlarmClock *)alarmClock
{
    if(alarmClock && self.pedometerAlarmClockMap)
    {
        //配对流程，deviceId为空
        if(alarmClock.deviceId.length==0)
        {
            [self.protocolHandleCenter setAlarmClock:alarmClock];
            return YES;
        }
        else
        {
            NSString *alarmClockKey=[alarmClock.deviceId uppercaseString];
            if(![self.pedometerAlarmClockMap objectForKey:alarmClockKey])
            {
                //测量数据上传流程，deviceid不为空
                [self.pedometerAlarmClockMap setObject:alarmClock forKey:alarmClockKey];
                return YES;
            }
            else
            {
                //重复添加同一个对象
                [self.pedometerAlarmClockMap removeObjectForKey:alarmClockKey];
                [self.pedometerAlarmClockMap setObject:alarmClock forKey:alarmClockKey];
                return YES;
            }
        }
    }
    else
    {
        NSString *msg=[NSString stringWithFormat:@"Failed to set pedometer alarm clock...%@",[LSFormatConverter dictionaryWithProperty:alarmClock]];
        [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
}
/*
 *  设备产品的用户信息
 */
-(BOOL)setProductUserInfo:(LSProductUserInfo *)userInfo
{
    if(userInfo && self.productUserInfoMap)
    {
        //配对流程，下写用户信息，deviceId为空
        if(userInfo.deviceId.length==0)
        {
            [self.protocolHandleCenter setLocalProductUserInfo:userInfo];
            return true;
        }
        else
        {
            NSString *userInfoKey=[userInfo.deviceId uppercaseString];
            if(![self.productUserInfoMap objectForKey:userInfoKey])
            {
                //测量数据上传流程，写用户信息，deviceid不为空
                [self.productUserInfoMap setObject:userInfo forKey:userInfoKey];
                return true;
            }
            else
            {
                //重复添加同一个设备用户信息对象
                [self.productUserInfoMap removeObjectForKey:userInfoKey];
                [self.productUserInfoMap setObject:userInfo forKey:userInfoKey];
                return true;
            }
        }
    }
    else
    {
        NSString *msg=[NSString stringWithFormat:@"Failed to set product user info...%@",[LSFormatConverter dictionaryWithProperty:userInfo]];
        [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
}

/*
 * 新增加接口，设置A2设备的声音振动提示功能
 */
-(BOOL)setVibrationVoice:(LSVibrationVoice *)vibrationVoice
{
    if(vibrationVoice && self.vibrationVoiceMap)
    {
        //配对流程，写声音振动提示功能，deviceId为空
        if(vibrationVoice.deviceId.length==0)
        {
            [self.protocolHandleCenter setVibrationVoice:vibrationVoice];
            return YES;
        }
        else
        {
            NSString *vibrationVoiceKey=[vibrationVoice.deviceId uppercaseString];
            if(![self.vibrationVoiceMap objectForKey:vibrationVoiceKey])
            {
                
                //测量数据上传流程，写声音振动提示功能，deviceid不为空
                [self.vibrationVoiceMap setObject:vibrationVoice forKey:vibrationVoiceKey];
                return YES;
            }
            else
            {
                //重复添加同一个设备用户信息对象
                [self.vibrationVoiceMap removeObjectForKey:vibrationVoiceKey];
                [self.vibrationVoiceMap setObject:vibrationVoice forKey:vibrationVoiceKey];
                return YES;
            }
        }
    }
    else
    {
        NSString *msg=[NSString stringWithFormat:@"Failed to set vibration voice...%@",[LSFormatConverter dictionaryWithProperty:vibrationVoice]];
        [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
    
}

/*
 *  设置测量设备列表,测量设备列表的key为broadcastId大写或peripheralIdentifier(A3.1协议专用)
 */
-(void)setMeasureDeviceList:(NSArray *)deviceList
{
    //先清空，再添加
    if(self.enableMeasureDeviceMap && [self.enableMeasureDeviceMap count]>0)
    {
        [self.enableScanDeviceType removeAllObjects];
        [self.enableMeasureDeviceMap removeAllObjects];
    }
    if(deviceList && self.enableMeasureDeviceMap)
    {
        self.enableScanDeviceType=[[NSMutableArray alloc] init];
        
        for (id device in deviceList)
        {
            if([device isKindOfClass:[LSDeviceInfo class]])
            {
                LSDeviceInfo *tempDevice=(LSDeviceInfo *)device;
                
                //默认是用devicetype+broadcastId作为设备Map的key
                NSString *deviceKey=[NSString stringWithFormat:@"%d%@",tempDevice.deviceType,tempDevice.broadcastId];
                
                //对于A3.1,Philips设备，由于该协议类型的设备在广播时没有broadcastId,所以设备Map的key为perpherial对象的identifier
                if([PROTOCOL_TYPE_A3_1 isEqualToString:tempDevice.protocolType])
                {
                    deviceKey=[NSString stringWithFormat:@"%d%@",tempDevice.deviceType,tempDevice.peripheralIdentifier];
                }
                [self addMeasuredDeviceToMap:tempDevice key:deviceKey];
            }
        }
        
    }
    
}
/*
 *  动态添加单一个测量设备
 */
-(BOOL)addMeasureDevice:(LSDeviceInfo *)lsDevice
{
    if(lsDevice && self.enableMeasureDeviceMap)
    {
        //默认是用devicetype+broadcastId作为设备Map的key
        NSString *deviceKey=[NSString stringWithFormat:@"%d%@",lsDevice.deviceType,lsDevice.broadcastId];
        
        //对于A3.1,Philips设备，由于该协议类型的设备在广播时没有broadcastId,所以设备Map的key为perpherial对象的identifier
        if([PROTOCOL_TYPE_A3_1 isEqualToString:lsDevice.protocolType])
        {
            deviceKey=[NSString stringWithFormat:@"%d%@",lsDevice.deviceType,lsDevice.peripheralIdentifier];
        }
        
        [self addMeasuredDeviceToMap:lsDevice key:deviceKey];
        return YES;
    }
    else
    {
        [self managerDebugMessage:@"Failed to add measure device,is nil.." debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
}

/*
 *  动态删除一个测量设备
 */
-(BOOL)deleteMeasureDevice:(NSString *)broadcastId
{
    NSString *msg=nil;
    if (broadcastId.length==0 ||[self.enableMeasureDeviceMap count]==0)
    {
        [self managerDebugMessage:@"Failed to delete measure device,is nil..." debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
    else
    {
        //默认是用broadcastId作为设备Map的key
        NSString *deviceKey=broadcastId;
        deviceKey=[deviceKey uppercaseString];
        for (NSString *key in self.enableMeasureDeviceMap)
        {
            if([key hasSuffix:deviceKey])
            {
                msg=[NSString stringWithFormat:@"delete measure device with key:%@",key];
                [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
                [self.enableMeasureDeviceMap removeObjectForKey:key];
                return YES;
                
            }
        }
        return NO;
    }
}

/*
 *  根据设备类型、广播类型，搜索乐心设备
 */
-(BOOL)searchLsBleDevice:(NSArray *)deviceTypes ofBroadcastType:(BroadcastType)broadcastType searchCompletion:(void(^)(LSDeviceInfo* lsDevice))searchCompletion;
{
    if(deviceTypes && searchCompletion && self.currentWorkStatus==MANAGER_WORK_STATUS_IBLE)
    {
        self.enableScanServices=[LSDeviceProfiles getGattServicesFromDeviceType:deviceTypes];
        self.currentWorkStatus=MANAGER_WORK_STATUS_SCAN;
        self.searchCompletionBlock=searchCompletion;
        self.bleConnector.bleConnectorDelegate=self;
        self.currentBroadcastType=broadcastType;
        [self.lsPeripheralMap removeAllObjects];
        return  [self.bleConnector scanWithServices:self.enableScanServices];
        
    }
    else return NO;
}

/*
 *  停止搜索
 */
-(BOOL)stopSearch
{
    if(self.currentWorkStatus==MANAGER_WORK_STATUS_SCAN)
    {
        self.currentWorkStatus=MANAGER_WORK_STATUS_IBLE;
        [self.bleConnector stopScan];
        return YES;
    }
    else return NO;
}

/*
 *  与设备进行配对
 */
-(BOOL)pairWithLsDeviceInfo:(LSDeviceInfo *)lsDevice pairedDelegate:(id<LSBlePairingDelegate>)pairedDelegate
{
    NSString *msg=nil;
    
    if(lsDevice && pairedDelegate)
    {
        BOOL isDeviceTypeValid=[self.lsDeviceTypeRange containsObject:[NSNumber numberWithInt:lsDevice.deviceType]];
        if(lsDevice.deviceName.length==0 || !isDeviceTypeValid)
        {
            msg=[NSString stringWithFormat:@"Failed to pair device,for device info invalid,deviceName = %@, deviceType = %d",lsDevice.deviceName,lsDevice.deviceType];
            [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
            return NO;
        }
        else if(self.currentWorkStatus==MANAGER_WORK_STATUS_IBLE)
        {
            [self cancelRestartScanTimer];
            self.currentWorkStatus=MANAGER_WORK_STATUS_PAIR;
            self.pairedDelegate=pairedDelegate;
            self.protocolHandleCenter.bleProtocolDelegate=self;
            
            //获取自定义的广播ID,没有则返回nil;
            lsDevice.broadcastId=[self checkingCustomBroadcastID:lsDevice.deviceName deviceType:lsDevice.deviceType];
            
            NSString *perpheralKey=nil;
            
            if([PROTOCOL_TYPE_A3_1 isEqualToString:lsDevice.protocolType])
            {
                perpheralKey=lsDevice.peripheralIdentifier;
            }
            else
            {
                perpheralKey=lsDevice.deviceName;
            }
            
            CBPeripheral *lsPeripheral=[self getLsPeripheralWithKey:perpheralKey];
            
            NSArray *pairingProtocolQueue=[LSProtocolClassifier protocolProcesses:lsDevice workingMode:PAIRING_DEVICE_MODE deviceUserInfo:[self getDeviceUserInfoSetting]];
            
            [self.protocolHandleCenter pairingWithDevice:lsDevice peripheral:lsPeripheral protocolProcesses:pairingProtocolQueue count:0];
            return YES;
        }
        else
        {
            [self managerDebugMessage:@"Failed to pair device,because of current work status" debuglevel:DEBUG_LEVEL_GENERAL];
            return NO;
        }
    }
    else
    {
        [self managerDebugMessage:@"Failed to pair device for nil...." debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
}

/*
 *  A3设备的绑定设备用户编号
 */
-(BOOL)bindingDeviceUsers:(NSUInteger)userNumber userName:(NSString *)name
{
    NSString *msg=nil;
    if(name.length==0 || userNumber==0 || name.length >50)
    {
        msg=[NSString stringWithFormat:@"Failed to binding device user with userNumber(%lu),and userName(%@)",(unsigned long)userNumber,name];
        [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
    else
    {
        //debug message
        msg=[NSString stringWithFormat:@"binding device user with userNumber(%lu),and userName(%@)",(unsigned long)userNumber,name];
        [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
        [self.protocolHandleCenter bindingDeviceUsers:userNumber userName:name];
        return YES;
    }
}
/*
 *  停止接收蓝牙测量数据的服务
 */
-(BOOL)stopDataReceiveService
{
    if(self.bleConnector && self.protocolHandleCenter)
    {
        //debug message
        [self managerDebugMessage:@"stop data receive service...." debuglevel:DEBUG_LEVEL_GENERAL];
        self.disableStartDataReceive=YES;
        
        self.currentWorkStatus=MANAGER_WORK_STATUS_IBLE;
        [self.bleConnector stopScan];
        [self.protocolHandleCenter interruptCurrentTask];

        [self cancelRestartScanTimer];
        return true;
    }
    else return false;
}

/*
 *  启动自动接收数据的服务
 */
-(BOOL)startDataReceiveService:(id<LSBleDataReceiveDelegate>)dataDelegate
{
    NSString *msg=nil;
    if (dataDelegate && self.currentWorkStatus==MANAGER_WORK_STATUS_IBLE)
    {
        //debug message
        msg=[NSString stringWithFormat:@"try to start data receive service,device count(%lu)",(unsigned long)[self.enableMeasureDeviceMap count]];
        [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
        
        self.currentWorkStatus=MANAGER_WORK_STATUS_UPLOAD;
        self.dataReceiveDelegate=dataDelegate;
        
        self.protocolHandleCenter.bleProtocolDelegate=self;
        self.bleConnector.bleConnectorDelegate=self;
        self.disableStartDataReceive=NO;
        
        [self startupDataReceiveService];
        return YES;
        
    }
    else
    {
        //debug message
        msg=[NSString stringWithFormat:@"Failed to start data receive service for working status..."];
        [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
    
}

//设置允许扫描的广播名称列表
-(BOOL)setEnableScanBrocastName:(NSArray*)enableDevices
{
    if(enableDevices)
    {
        self.enableSpecialConditions=YES;
        self.enableScanBroadcastNames=enableDevices;
        return YES;
    }
    else
    {
        self.enableSpecialConditions=NO;
        return NO;
    }
    
}

//根据电阻值计算相关的脂肪数据
-(LSWeightAppendData *)parseAdiposeDataWithResistance:(double)resistance_2 userHeight:(double)height_m userWeight:(double)weight_kg userAge:(int)age userSex:(UserSexType)sex
{
    LSWeightAppendData *adiposeData=[[LSWeightAppendData alloc] init];
    
    //水分含量
    adiposeData.bodywaterRatio=[LSFatParser waterByHeigth:height_m weight:weight_kg imp:resistance_2 sex:sex];
    
    adiposeData.bodyFatRatio=[LSFatParser fatByHeigth:height_m weight:weight_kg imp:resistance_2 age:age sex:sex];
    
    //肌肉含量
    adiposeData.muscleMassRatio=[LSFatParser muscleByWeight:weight_kg fat:adiposeData.bodyFatRatio sex:sex];
    
    //骨质量
    adiposeData.boneDensity=[LSFatParser boneByMuscl:adiposeData.muscleMassRatio sex:sex];
    
    //基础代谢
    adiposeData.basalMetabolism=[LSFatParser basalMetabolismByMuscl:adiposeData.muscleMassRatio weight:weight_kg age:age sex:sex];
    
    adiposeData.bmiLevel = [LSFatParser calculateBMIWithWeight:weight_kg withHeight:height_m];
    
    return adiposeData;
}

//版本1.0.8新增接口，启动血压计开始测量
-(BOOL)startMeasuring
{
    if(self.protocolHandleCenter)
    {
        return [self.protocolHandleCenter writeCommandToStartMeasuring];
    }
    else return NO;
}

//版本1.0.8新增接口，连接通过命令启动测量的血压计设备
-(BOOL)connectDevice:(LSDeviceInfo *)pairedDevice connectDelegate:(id<LSDeviceConnectDelegate>)connectDelegate
{
    if(pairedDevice && pairedDevice.broadcastId.length>0 && [pairedDevice.protocolType isEqualToString:@"COMMAND_START"])
    {
        self.deviceConnectDelegate=connectDelegate;
        
        self.protocolHandleCenter.bleProtocolDelegate=self;
        
        self.currentWorkStatus=MANAGER_WORK_STATUS_CONNECT;
        
        //根据deviceName获取CBPeripheral对象
        CBPeripheral *lsPeripheral=[self getLsPeripheralWithKey:pairedDevice.broadcastId];
        
        NSArray *uploadingProtocolQueue=[LSProtocolClassifier protocolProcesses:pairedDevice workingMode:PAIRING_DEVICE_MODE deviceUserInfo:[self getDeviceUserInfoSetting]];
        
        //连接指定的已配对的设备，读取测量数据
        [self.protocolHandleCenter uploadingWithDevice:pairedDevice peripheral:lsPeripheral protocolProcesses:uploadingProtocolQueue count:0];
        
        return YES;
    }
    else return NO;
}

//版本1.0.8新增接口，根据指定的设备类型、设备名称设置配对时采用固定的广播ID接口
-(BOOL) setCustomBroadcastID:(NSString *)customBroadcastID deviceName:(NSString *)deviceName deviceType:(NSArray*)deviceTypes
{
    if([LSFormatConverter checkCustomBroadcastID:customBroadcastID])
    {
        self.mCustomBroadacstID=[customBroadcastID uppercaseString];
        self.mDeviceName=deviceName;
        self.mDeviceTypes=deviceTypes;
        return YES;
    }
    else return  NO;
}

//版本V2.0.0新增接口，用于设置是否允许输出log调试信息
-(void)setDebugModeWithPermissions:(NSString *)key
{
    if([@"sky" isEqualToString:key])
    {
        [BleDebugLogger setDebugMode:YES];
    }
}

//版本V3.0.2 新增接口，取消配对过程
-(void)cancelPairingProcess
{
    if (self.currentWorkStatus==MANAGER_WORK_STATUS_PAIR)
    {
        [BleDebugLogger object:self printMessage:@"cancel pairing process,now..." withDebugLevel:DEBUG_LEVEL_GENERAL];
        
        self.currentWorkStatus=MANAGER_WORK_STATUS_IBLE;

        [self.protocolHandleCenter interruptCurrentTask];
        
    }
}


#pragma mark - private methods

-(void)managerDebugMessage:(NSString *)msg debuglevel:(DebugLevel)level
{
    [BleDebugLogger object:self printMessage:msg withDebugLevel:level];
}

-(NSDictionary *)getDeviceUserInfoSetting
{
    NSMutableDictionary *userInfoSetting=[[NSMutableDictionary alloc] init];
    
    LSProductUserInfo *fatScaleUserInfo=self.protocolHandleCenter.localProductUserInfo;
    LSVibrationVoice *vibrationVoice=self.protocolHandleCenter.vibrationVoice;
    LSPedometerUserInfo *pedometerUserInfo=self.protocolHandleCenter.pedometerUserInfo;
    LSPedometerAlarmClock *alarmClock=self.protocolHandleCenter.alarmClock;
    
    if(fatScaleUserInfo)
    {
        [userInfoSetting setValue:fatScaleUserInfo forKey:KEY_WEIGHT_SCALE_USER_INFO];
    }
    if(vibrationVoice)
    {
        [userInfoSetting setValue:vibrationVoice forKey:KEY_WEIGHT_SCALE_VIBRATION_VOICE];
    }
    if(pedometerUserInfo)
    {
        [userInfoSetting setValue:pedometerUserInfo forKey:KEY_PEDOMETER_USER_INFO];
    }
    if(alarmClock)
    {
        [userInfoSetting setValue:alarmClock forKey:KEY_PEDOMETER_ALARM_CLOCK];
    }
    
    return [[NSDictionary alloc] initWithDictionary:userInfoSetting];
    
}


-(void)addMeasuredDeviceToMap:(LSDeviceInfo *)device key:(NSString *)deviceKey
{
    NSString *keyMsg=nil;
    if(deviceKey.length)
    {
        //将key转换成大写,以大写形式保存
        deviceKey=[deviceKey uppercaseString];
        
        if([self.enableMeasureDeviceMap objectForKey:deviceKey])
        {
            //删除旧的对象信息
            [self.enableMeasureDeviceMap removeObjectForKey:deviceKey];
        }
        
        //添加新的设备对象信息
        [self.enableMeasureDeviceMap setObject:device forKey:deviceKey];
        
        //根据当前的设备类型，设置允许扫描的设备类型
        if(![self.enableScanDeviceType containsObject:@(device.deviceType)])
        {
            [self.enableScanDeviceType addObject:@(device.deviceType)];
        }
        
        //debug message
        [self managerDebugMessage:[NSString stringWithFormat:@"add measured device with key-%@",deviceKey] debuglevel:DEBUG_LEVEL_SUPREME];
    }
    else
    {
        keyMsg=[NSString stringWithFormat:@"Error,failed to add measured device with key-%@",deviceKey];
        [self managerDebugMessage:keyMsg debuglevel:DEBUG_LEVEL_GENERAL];
    }
    
}

//根据当前的设备名称、设备类型检查是否有自定义的广播ID
-(NSString *)checkingCustomBroadcastID:(NSString *)deviceName deviceType:(LSDeviceType)deviceType
{
    NSString *customValue=nil;
    
    if(self.mCustomBroadacstID.length)
    {
        customValue=self.mCustomBroadacstID;
    }
    if(self.mDeviceName.length)
    {
        if([deviceName isEqualToString:self.mDeviceName])
        {
            customValue=self.mCustomBroadacstID;
        }
        else customValue=nil;
        
    }
    if(self.mDeviceTypes.count)
    {
        if([self.mDeviceTypes containsObject:@(deviceType)])
        {
            customValue=self.mCustomBroadacstID;
        }
        else customValue=nil;
    }
    
    return customValue;
}

-(void)initDeviceUserInfoSetting:(NSString *)deviceId
{
    NSString* userInfoKey=[deviceId uppercaseString];
    
    //从用户信息Map中取出用户信息对象
    if([self.productUserInfoMap count] && [self.productUserInfoMap objectForKey:userInfoKey])
    {
        //设置产品的用户信息
        LSProductUserInfo *userInfo=(LSProductUserInfo *)[self.productUserInfoMap objectForKey:userInfoKey];
        [self.protocolHandleCenter setLocalProductUserInfo:userInfo];
    }
    
    //从声音振动提示信息对象map表中，取出当前连接的设备
    if([self.vibrationVoiceMap count] &&[self.vibrationVoiceMap objectForKey:userInfoKey])
    {
        LSVibrationVoice *vibrationVoice=(LSVibrationVoice *)[self.vibrationVoiceMap objectForKey:userInfoKey];
        [self.protocolHandleCenter setVibrationVoice:vibrationVoice];
    }
    
    if([self.pedometerUserInfoMap count] && [self.pedometerUserInfoMap objectForKey:userInfoKey])
    {
        LSPedometerUserInfo *pedometerUserInfo=(LSPedometerUserInfo *)[self.pedometerUserInfoMap objectForKey:userInfoKey];
        [self.protocolHandleCenter setPedometerUserInfo:pedometerUserInfo];
    }
    
    if([self.pedometerAlarmClockMap count] && [self.pedometerAlarmClockMap objectForKey:userInfoKey])
    {
        LSPedometerAlarmClock *alarmClock=(LSPedometerAlarmClock *)[self.pedometerAlarmClockMap objectForKey:userInfoKey];
        [self.protocolHandleCenter setAlarmClock:alarmClock];
    }
    
}

/*
 *  启动数据接收服务
 */
-(void)startupDataReceiveService
{
    if(!self.disableStartDataReceive)
    {
        //debug message
        [self managerDebugMessage:@"successfuly to start up data receive service......" debuglevel:DEBUG_LEVEL_SUPREME];
        [self.lsPeripheralMap removeAllObjects];
        self.isDataReceiveServiceStart=YES;
        self.bleConnector.bleConnectorDelegate=self;
        if([self.bleConnector isScanning])
        {
            [self.bleConnector stopScan];
        }
        
        self.enableScanServices=[LSDeviceProfiles getGattServicesFromDeviceType:self.enableScanDeviceType];
        [self.bleConnector scanWithServices: self.enableScanServices];
        
        //初始化重新扫描的定时监听器，若启动扫描三分钟后，没有扫描到相应的设备处于测量状态，刚先停止扫描，再重新启动扫描
//        [self performSelectorOnMainThread:@selector(installRestartScanTimer) withObject:nil waitUntilDone:NO];
        [self installRestartScanTimer];
    }
}

-(void)cancelRestartScanTimer
{
    if(self.restartScanTimer)
    {
        [self managerDebugMessage:@"cancel restart scan timer..." debuglevel:DEBUG_LEVEL_SUPREME];
        [self.restartScanTimer cancel];
        self.restartScanTimer=nil;
    }

}

-(void)installRestartScanTimer
{
    [self cancelRestartScanTimer];
    [self managerDebugMessage:@"install restart scan timer for 1 minute..." debuglevel:DEBUG_LEVEL_SUPREME];
    int restartScanTime=1*6*10.0;//默认为1分钟
//    self.restartScanTimer= [NSTimer scheduledTimerWithTimeInterval:restartScanTime target:self selector:@selector(restartScan) userInfo:nil repeats:NO];
   self.restartScanTimer = [DispatchBasedTimer timerWithDispatchQueue:self.bleConnector.dispatchQueue
                                                                                timeoutInMilliSeconds:restartScanTime * 1000
                                                                                       andBlock:^{
                                                                                                  [self restartScan];
                                                                                                 }];
    
}

-(void)restartScan
{
    if(self.disableStartDataReceive)
    {
        [self managerDebugMessage:@"warning,can't restart scan with work status.. " debuglevel:DEBUG_LEVEL_SUPREME];
        [self cancelRestartScanTimer];
    }
    else
    {
        [self managerDebugMessage:@"stop and restart scan...." debuglevel:DEBUG_LEVEL_SUPREME];
        [self startupDataReceiveService];
    }
    
}

/*
 *  乐心设备类型范围
 */
-(NSArray *)lsDeviceTypeRange
{
    if(!_lsDeviceTypeRange)
    {
        _lsDeviceTypeRange=@[@(LS_WEIGHT_SCALE),
                             @(LS_SPHYGMOMETER),
                             @(LS_HEIGHT_MIRIAM),
                             @(LS_PEDOMETER),
                             @(LS_FAT_SCALE),
                             @(LS_KITCHEN_SCALE)];
    }
    return _lsDeviceTypeRange;
}


-(NSMutableDictionary *)lsPeripheralMap
{
    if(!_lsPeripheralMap)
    {
        _lsPeripheralMap=[[NSMutableDictionary alloc] init];
    }
    return _lsPeripheralMap;
}


-(CBPeripheral *)getLsPeripheralWithKey:(NSString *)key
{
    NSString *msg=nil;
    if(key && [self.lsPeripheralMap count])
    {
        id tempLsPeripheral=[self.lsPeripheralMap valueForKey:key];
        if([tempLsPeripheral isKindOfClass:[CBPeripheral class]])
        {
            return (CBPeripheral *)tempLsPeripheral;
        }
        else
        {
            //debug message
            msg=[NSString stringWithFormat:@"Failed to get CBPeripheral,because of key is invalid ? (%@)",key];
            [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
            return nil;
        }
        
    }
    else
    {
        //debug message
        msg=[NSString stringWithFormat:@"Failed to get CBPeripheral with key(%@)",key];
        [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        return nil;
    }
}

-(BOOL)checkingScanFilterSetting:(NSString *)deviceName flag:(NSInteger)pairFlag
{
    BOOL isValid=NO;
    
    if (deviceName.length)
    {
        //判断扫描条件约束
        if(self.currentBroadcastType==BROADCAST_TYPE_ALL)
        {
            isValid=YES;
        }
        else if(self.currentBroadcastType==BROADCAST_TYPE_NORMAL && pairFlag==0)
        {
            isValid=YES;
        }
        else if(self.currentBroadcastType==BROADCAST_TYPE_PAIR && pairFlag==1)
        {
            if(self.enableSpecialConditions)
            {
                if(self.enableScanBroadcastNames)
                {
                    for (NSString *tempName in self.enableScanBroadcastNames)
                    {
                        NSString *currentName=nil;
                        if([deviceName length]>5)
                        {
                            currentName= [deviceName substringWithRange:NSMakeRange(0, 5)];
                        }
                        else
                        {
                            currentName= [deviceName substringFromIndex:0];
                            
                        }
                        
                        if([tempName isEqualToString:currentName])
                        {
                            isValid=YES;
                        }
                    }
                }
                else isValid=NO;
            }
            else isValid=YES;
        }
    }
    
    return isValid;
    
}
/*
 *  处理测量数据上传模式下的扫描结果
 */
-(void)handleDataUploadModeScanResults:(NSString *)broadcastName serviceValue:(NSString*)serviceUUID identifier:(NSUUID *)peripheralIdentifier manufacturerData:(NSString *)manufactData
{
    if([self.enableMeasureDeviceMap count])
    {
        NSString *msg=nil;
        NSString *deviceKey=nil;
        NSString *peripheralKey =nil;
        NSString *tempProtocolType=[LSDeviceProfiles getProtocolTypeFromServices:serviceUUID];
        LSDeviceType deviceType =[LSDeviceProfiles getDeviceTypeFromServices:serviceUUID];
        
        if([PROTOCOL_TYPE_GENERIC_FAT isEqualToString:tempProtocolType]
           ||[PROTOCOL_TYPE_KITCHEN isEqualToString:tempProtocolType])
        {
            //通用脂肪秤协议的设备不存在广播ID，为“0000000000”,加上设备名称
            deviceKey=[broadcastName substringFromIndex:1];
            peripheralKey=[broadcastName substringFromIndex:1];
            
        }
        else if([PROTOCOL_TYPE_A3_1 isEqualToString:tempProtocolType])
        {
            deviceKey=peripheralIdentifier.UUIDString;
            
            peripheralKey=peripheralIdentifier.UUIDString;
        }
        else
        {
            peripheralKey=[broadcastName substringFromIndex:1];
            
            NSInteger index=broadcastName.length-8;
            if(index>=0)
            {
                deviceKey=[broadcastName substringWithRange:NSMakeRange(index, 8)];
            }
            else if(broadcastName.length>6)
            {
                deviceKey=[broadcastName substringFromIndex:6];
            }
            else
            {
                deviceKey=[broadcastName substringFromIndex:1];
            }
        }
        
        deviceKey=[NSString stringWithFormat:@"%d%@",deviceType,deviceKey];
        deviceKey=[deviceKey uppercaseString];
        
        LSDeviceInfo *measuredDevice=(LSDeviceInfo *)[self.enableMeasureDeviceMap objectForKey:deviceKey];
        CBPeripheral *lsPeripheral=[self getLsPeripheralWithKey:peripheralKey];
        
        if(measuredDevice && lsPeripheral)
        {
            //debug message
            msg=[NSString stringWithFormat:@"successfuly to get device from map by broadcastId(%@),device info %@",deviceKey,[LSFormatConverter dictionaryWithProperty:measuredDevice]];
            [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
            
            //初始化设备用户信息的设置
            [self initDeviceUserInfoSetting:measuredDevice.deviceId];
            
            measuredDevice.protocolType=tempProtocolType;
            
            NSArray *uploadingProtocolQueue=[LSProtocolClassifier protocolProcesses:measuredDevice workingMode:DATA_UPLOADING_MODE deviceUserInfo:[self getDeviceUserInfoSetting]];
    
            [self cancelRestartScanTimer];
            //停止扫描
            [self.bleConnector stopScan];
            self.protocolHandleCenter.bleProtocolDelegate=self;
            //连接指定的已配对的设备，读取测量数据
            [self.protocolHandleCenter uploadingWithDevice:measuredDevice peripheral:lsPeripheral protocolProcesses:uploadingProtocolQueue count:0];
           
        }
        else
        {
            //debug message
            msg=[NSString stringWithFormat:@"get device by broadcastId(%@),has device ? (%@)",deviceKey,measuredDevice];
            [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        }
    }
}

/*
 *  处理正常模式下的扫描结果，返回扫描结果时，须判断所设置的扫描条件
 */
-(void)handleNormalModeScanResults:(NSString *)broadcastName serviceValue:(NSString*)serviceUUID key:(NSString *)peripheralKey identifier:(NSUUID *)peripheralIdentifier manufacturerData:(NSString *)manufacturerData withPeripheral:(CBPeripheral *)periperal

{
    LSDeviceInfo  *lsDevice = [[LSDeviceInfo alloc] init];
    lsDevice.protocolType=[LSDeviceProfiles getProtocolTypeFromServices:serviceUUID];
    lsDevice.peripheralIdentifier=peripheralIdentifier.UUIDString;
    lsDevice.deviceType =[LSDeviceProfiles getDeviceTypeFromServices:serviceUUID];
    lsDevice.lsCBPeripheral = periperal;
    NSInteger pairFlag = 0;
    
    lsDevice.deviceName =[broadcastName substringFromIndex:1];
    if([PROTOCOL_TYPE_A3_1 isEqualToString:lsDevice.protocolType])
    {
        //A3.1协议的philips设备在广播包里没有broadcastId信息，只有model
        lsDevice.modelNumber=[broadcastName substringFromIndex:1];
        if([lsDevice.modelNumber length]>6)
        {
            lsDevice.modelNumber=[lsDevice.modelNumber substringToIndex:6];
        }
    }
    else
    {
        lsDevice.modelNumber = [LSFormatConverter getModelNumberFromBroadcastName:broadcastName];
    }
    pairFlag = [[broadcastName substringWithRange:NSMakeRange(0, 1)] integerValue];
    lsDevice.preparePair = pairFlag;
    //非配对模式
    if(pairFlag==0)
    {
        if([PROTOCOL_TYPE_GENERIC_FAT isEqualToString:lsDevice.protocolType]
           ||[PROTOCOL_TYPE_KITCHEN isEqualToString:lsDevice.protocolType])
        {
            //通用脂肪秤,kitchen scale 没有广播ID,设置默认值
            lsDevice.broadcastId=lsDevice.deviceName;
        }
        else if([PROTOCOL_TYPE_BLOOD_PRESSURE_COMMAND_START isEqualToString:lsDevice.protocolType])
        {
            lsDevice.broadcastId=peripheralKey;
        }
        else
        {
            NSInteger index=lsDevice.deviceName.length-8;
            if(index>=0)
            {
                lsDevice.broadcastId=[lsDevice.deviceName substringWithRange:NSMakeRange(index, 8)];
            }
            else if(lsDevice.deviceName.length>6)
            {
                lsDevice.broadcastId=[lsDevice.deviceName substringFromIndex:6];
            }
            else lsDevice.broadcastId=lsDevice.deviceName;
        }
    }
    
    
    //检查当前设置的扫描条件
    if([self checkingScanFilterSetting:lsDevice.deviceName flag:pairFlag])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(self.searchCompletionBlock)
            {
                self.searchCompletionBlock(lsDevice);
            }
        });
    }
}



#pragma mark - LSBleConnector Delegate

/*
 *  由LSBleConnector 返回的扫描结果
 */
-(void)bleConnectorDidScanResults:(CBPeripheral *)peripheral broadcastName:(NSString *)broadcastName serviceLists:(NSArray *)services manufacturerData:(NSString *)manufacturerData
{
    CBUUID *serviceUUID = [services objectAtIndex:0];
    NSString *scanMsg=nil;
    
    if (broadcastName.length && [self.enableScanServices containsObject:serviceUUID])
    {
        if(broadcastName.length<5)
        {
            scanMsg=[NSString stringWithFormat:@"unhandle scan results with broadcast-%@",broadcastName];
            [self managerDebugMessage:scanMsg debuglevel:DEBUG_LEVEL_GENERAL];
        }
        else
        {
            NSString *tempProtocolType=[LSDeviceProfiles getProtocolTypeFromServices:serviceUUID.UUIDString];
            NSString *peripheralKey=nil;
            
            if([PROTOCOL_TYPE_BLOOD_PRESSURE_COMMAND_START isEqualToString:tempProtocolType])
            {
                NSInteger pairFlag = [[broadcastName substringWithRange:NSMakeRange(0, 1)] integerValue];
                
                if (pairFlag==0 && manufacturerData.length>12)
                {
                    //正常广播状态，以manufacturerData作为peripheral的Map关系表的key
                    peripheralKey=[manufacturerData substringFromIndex:[manufacturerData length]-12];
                }
                else
                {
                    //配对状态，以deviceName作为peripheral的Map关系表的key
                    peripheralKey= [broadcastName substringFromIndex:1];
                }
            }
            else if ([PROTOCOL_TYPE_A3_1 isEqualToString:tempProtocolType])
            {
                peripheralKey=peripheral.identifier.UUIDString;
            }
            else
            {
                //设置peripheral的Map关系表
                peripheralKey =[broadcastName substringFromIndex:1];
            }
            
            if(peripheralKey.length>0 && peripheral)
            {
                NSString *msg=[NSString stringWithFormat:@"put device to map with peripheral key (%@)",peripheralKey];
                [self managerDebugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
                [self.lsPeripheralMap setObject:peripheral forKey:peripheralKey];
            }
            
            
            if(self.currentWorkStatus==MANAGER_WORK_STATUS_SCAN)
            {
                //普通的扫描模式
                //直接返回扫描结果
                [self handleNormalModeScanResults:broadcastName serviceValue:serviceUUID.UUIDString key:peripheralKey identifier:peripheral.identifier manufacturerData:manufacturerData withPeripheral:peripheral];
            }
            else  if(self.currentWorkStatus==MANAGER_WORK_STATUS_UPLOAD)
            {
                //测量数据上传模式下的扫描结果
                [self handleDataUploadModeScanResults:broadcastName serviceValue:serviceUUID.UUIDString identifier:peripheral.identifier manufacturerData:manufacturerData];
            }
            
        }
    }
}
#pragma mark - LSBleStatusChangeDelegate
/*
 *  终端蓝牙状态改变
 */
-(void)bleConnectorDidBluetoothStatusChange:(NSInteger)bleState
{
    
    self.currentBleStatus=bleState;
    if(bleState==CBCentralManagerStatePoweredOff)
    {
        self.isBluetoothPowerOn=NO;
        
    }
    else if(bleState==CBCentralManagerStatePoweredOn)
    {
        self.isBluetoothPowerOn=YES;
    }
    //返回蓝牙状态信息
    if(self.checkBleStatusCompletionBlock)
    {
        if(bleState==CBCentralManagerStatePoweredOn)
        {
            self.checkBleStatusCompletionBlock(YES,self.isBluetoothPowerOn);
        }
        else
        {
            
            self.checkBleStatusCompletionBlock(NO,self.isBluetoothPowerOn);
        }
    }
    if(self.currentWorkStatus==MANAGER_WORK_STATUS_UPLOAD)
    {
        if(bleState==CBCentralManagerStatePoweredOff)
        {
            self.bleStatusChangeFlag=YES;
            
        }
        else if(bleState==CBCentralManagerStatePoweredOn)
        {
            if(self.bleStatusChangeFlag)
            {
                self.bleStatusChangeFlag=NO;
                [self stopDataReceiveService];
                self.currentWorkStatus=MANAGER_WORK_STATUS_UPLOAD;
                [self startupDataReceiveService];
            }
        }
    }
    
}


#pragma mark - LSProtocolHandleCenter Delegate

/*
 *  修改管理器当前的工作状态
 */
-(void)bleProtocolDidWorkStatusChange:(NSInteger)workStatus
{
    self.currentWorkStatus=workStatus;
}

/*
 *  用户信息设置成功的回调，3种用户信息
 */
-(void)bleProtocolDidWriteSuccessForUserInfo:(NSString *)deviceId memberId:(NSString *)memberId writeInfoType:(WriteInfoType)writeType
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(writeType==WRITE_PRODUCT_USER_INFO)
        {
            //产品用户信息设置成功
            if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidWriteSuccessForProductUserInfo:memberId:)])
            {
                [self.dataReceiveDelegate bleManagerDidWriteSuccessForProductUserInfo:deviceId memberId:memberId];
            }
        }
        else if (writeType==WRITE_PEDOMETER_USER_INFO)
        {
            //计步器用户信息设置成功
            if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidWriteSuccessForPedometerUserInfo:memberId:)])
            {
                [self.dataReceiveDelegate bleManagerDidWriteSuccessForPedometerUserInfo:deviceId memberId:memberId];
            }
        }
        else if (writeType==WRITE_ALARM_CLOCK)
        {
            //计步器闹钟信息设置成功
            if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidWriteSuccessForAlarmClock:memberId:)])
            {
                [self.dataReceiveDelegate bleManagerDidWriteSuccessForAlarmClock:deviceId memberId:memberId];
            }
        }
    });
}

/*
 *  接收A3设备发送过来的用户列表
 */
-(void)bleProtocolDidDiscoverdUserlist:(NSDictionary *)userlist
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if([self.pairedDelegate respondsToSelector:@selector(bleManagerDidDiscoverUserList:)])
        {
            [self.pairedDelegate bleManagerDidDiscoverUserList:userlist];
        }
    });
    
}

/*
 *  接收A3脂肪秤，发现设备的用户信息
 */
-(void)bleProtocolDidDiscoverdProductUserInfo:(LSProductUserInfo *)productUserInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveProductUserInfo:)])
        {
            [self.dataReceiveDelegate bleManagerDidReceiveProductUserInfo:productUserInfo];
        }
    });
    
    
}

/*
 *  接收配对结果
 */
-(void)bleProtocolDidPairedResults:(LSDeviceInfo *)pairedLsDevice pairedStatus:(NSInteger)pairedStatus
{
    //handler paired results
    self.currentWorkStatus=MANAGER_WORK_STATUS_IBLE;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if([self.pairedDelegate respondsToSelector:@selector(bleManagerDidPairedResults:pairStatus:)])
        {
            [self.pairedDelegate bleManagerDidPairedResults:pairedLsDevice pairStatus:pairedStatus];
        }
    });
    
}

/*
 *  接收数据上传完成标记
 */
-(void)bleProtocolDidDataReceiveComplete:(NSUInteger)completedFlag deviceId:(NSString *)deviceId
{
    
    if(completedFlag==1)
    {
        if([self.productUserInfoMap count] && [self.productUserInfoMap objectForKey:deviceId])
        {
            [self.productUserInfoMap removeObjectForKey:deviceId];
        }
    }
    else
    {
        [BleDebugLogger object:self printMessage:@"Failed to upload data..." withDebugLevel:DEBUG_LEVEL_GENERAL];
    }
    if(self.currentWorkStatus==MANAGER_WORK_STATUS_CONNECT)
    {
        [BleDebugLogger object:self printMessage:@"disconnect un handler..." withDebugLevel:DEBUG_LEVEL_GENERAL];
        return;
    }
    else
    {
        [self startupDataReceiveService];
    }
    
    
}

/*
 *接收不进行配对过程，而获取设备的详细信息
 */
-(void)bleProtocolDidDiscoverdDeviceInfo:(LSDeviceInfo *)deviceInfo
{
    if(deviceInfo)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidDiscoveredDeviceInfo:)])
            {
                [self.dataReceiveDelegate bleManagerDidDiscoveredDeviceInfo:deviceInfo];
            }
        });
        
    }
    
}

/*
 * 设备的连接状态改变，
 */
-(void)bleProtocolDidConnectStatusChange:(DeviceConnectState)connnectState broadcastId:(NSString *)broadcastId
{
    if(broadcastId)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidConnectStateChange:deviceName:)])
            {
                [self.dataReceiveDelegate bleManagerDidConnectStateChange:connnectState deviceName:broadcastId];
            }
            if([self.deviceConnectDelegate respondsToSelector:@selector(bleManagerDidConnectStateChange:)])
            {
                [self.deviceConnectDelegate bleManagerDidConnectStateChange:connnectState];
            }
            
        });
    }
    else
    {
        NSLog(@"Failed to return connect status.....%@",broadcastId);
    }
}


-(void)bleProtocolDidWaitingForCommandToStartMeasuring:(NSString *)deviceId
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([self.deviceConnectDelegate respondsToSelector:@selector(bleManagerDidWaitingForStartMeasuring:)])
        {
            [BleDebugLogger object:self printMessage:@"waiting for start measuring...." withDebugLevel:DEBUG_LEVEL_GENERAL];
            [self.deviceConnectDelegate bleManagerDidWaitingForStartMeasuring:deviceId];
        }
    });
    
    
    
}

/*
 *  接收测量数据
 */
-(void)bleProtocolDidReceiveMeasuredData:(id)measureData fromCharacteristic:(NSInteger)characteristicUuid device:(LSDeviceInfo *)deviceInfo
{
    if (!measureData && !deviceInfo)
    {
        return ;
    }
    LSDeviceType currentDeviceType=deviceInfo.deviceType;
    NSString *deviceId=deviceInfo.deviceId;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //先对测量数据进行分类，解析
        if(currentDeviceType==LS_HEIGHT_MIRIAM)
        {
            LSHeightData *heightData=[LSBleDataParsingTools parseHeightMeasurementData:measureData];
            heightData.deviceId=deviceId;
            heightData.deviceSn=[LSFormatConverter translateDeviceIdToSN:deviceId];
            heightData.broadcastId=deviceInfo.broadcastId;
            if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveHeightMeasuredData:)])
            {
                [self.dataReceiveDelegate bleManagerDidReceiveHeightMeasuredData:heightData];
            }
            
        }
        else if (currentDeviceType==LS_PEDOMETER)
        {
            LSPedometerData *pedometerData=[LSBleDataParsingTools parsePedometerScaleMeasurementData:measureData];
            pedometerData.deviceId=deviceId;
            pedometerData.broadcastId=deviceInfo.broadcastId;
            if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceivePedometerMeasuredData:)])
            {
                [self.dataReceiveDelegate bleManagerDidReceivePedometerMeasuredData:pedometerData];
            }
            
        }
        else if(currentDeviceType==LS_SPHYGMOMETER)
        {
            LSSphygmometerData *spData=[LSBleDataParsingTools parseSphygmometerMeasurementData:measureData];
            spData.deviceId=deviceId;
            spData.broadcastId=deviceInfo.broadcastId;
            if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveSphygmometerMeasuredData:)])
            {
                [self.dataReceiveDelegate bleManagerDidReceiveSphygmometerMeasuredData:spData];
            }
            if([self.deviceConnectDelegate respondsToSelector:@selector(bleManagerDidReceiveBloodPressureMeasuredData:)])
            {
                [self.deviceConnectDelegate bleManagerDidReceiveBloodPressureMeasuredData:spData];
            }
        }
        else if (currentDeviceType==LS_WEIGHT_SCALE)
        {
            if(characteristicUuid==WEIGHTSCALE_MEASUREMENT_CHARACTER)
            {
                LSWeightData *weightData=[LSBleDataParsingTools parseWeightScaleMeasurementData:measureData];
                weightData.deviceId=deviceId;
                weightData.broadcastId=deviceInfo.broadcastId;
                
                if(weightData.hasAppendMeasurement==1)
                {
                    self.tempWeightData=weightData;
                }
                else
                {
                    if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveWeightMeasuredData:)])
                    {
                        [self.dataReceiveDelegate bleManagerDidReceiveWeightMeasuredData:weightData];
                    }
                    if( self.currentWorkStatus==MANAGER_WORK_STATUS_PAIR && [self.pairedDelegate respondsToSelector:@selector(bleManagerDidReceiveWeightDataWithOperatingMode2:)])
                    {
                        [self.pairedDelegate bleManagerDidReceiveWeightDataWithOperatingMode2:weightData];
                    }
                    
                }
            }
            if(characteristicUuid==WEIGHTSCALE_APPENDMEASURE_CHARACTER)
            {
                LSWeightData *weightData=[LSBleDataParsingTools parseWeightAppendDataWithNormalWeight:self.tempWeightData sourceData:measureData];
                weightData.deviceId=deviceId;
                weightData.broadcastId=deviceInfo.broadcastId;
                
                if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveWeightMeasuredData:)])
                {
                    [self.dataReceiveDelegate bleManagerDidReceiveWeightMeasuredData:weightData];
                }
                if( self.currentWorkStatus==MANAGER_WORK_STATUS_PAIR &&  [self.pairedDelegate respondsToSelector:@selector(bleManagerDidReceiveWeightDataWithOperatingMode2:)])
                {
                    [self.pairedDelegate bleManagerDidReceiveWeightDataWithOperatingMode2:weightData];
                }
            }
        }
        else if(currentDeviceType==LS_FAT_SCALE)
        {
            if(characteristicUuid==FAT_SCALE_A3_MEASUREMENT_CHARACTER)
            {
                //没有脂肪测量数据
                LSWeightData *weightData=[LSBleDataParsingTools parseWeightScaleMeasurementData:measureData];
                weightData.deviceId=deviceId;
                weightData.broadcastId=deviceInfo.broadcastId;
                
                if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveWeightMeasuredData:)])
                {
                    [self.dataReceiveDelegate bleManagerDidReceiveWeightMeasuredData:weightData];
                }
                
            }
            else if(characteristicUuid==FAT_SCALE_A3_APPENDMEASURE_CHARACTER)
            {
                //有脂肪测量数据
                LSWeightAppendData *weightAppendData=[LSBleDataParsingTools parseWeightAppendData:measureData];
                weightAppendData.deviceId=deviceId;
                
                if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveWeightAppendMeasuredData:)])
                {
                    [self.dataReceiveDelegate bleManagerDidReceiveWeightAppendMeasuredData:weightAppendData];
                }
            }
            //版本1.0.7新增加部分，支持salter mibody a3脂肪秤
            else if(characteristicUuid==WEIGHTSCALE_MEASUREMENT_CHARACTER)
            {
                LSWeightData *weightData=[LSBleDataParsingTools parseWeightScaleMeasurementData:measureData];
                weightData.deviceId=deviceId;
                weightData.broadcastId=deviceInfo.broadcastId;
                
                if(weightData.hasAppendMeasurement==1)
                {
                    self.tempWeightData=weightData;
                }
                else
                {
                    if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveWeightMeasuredData:)])
                    {
                        [self.dataReceiveDelegate bleManagerDidReceiveWeightMeasuredData:weightData];
                    }
                    
                }
            }
            else if(characteristicUuid==WEIGHTSCALE_APPENDMEASURE_CHARACTER)
            {
                LSWeightData *weightData=[LSBleDataParsingTools parseWeightAppendDataWithNormalWeight:self.tempWeightData sourceData:measureData];
                weightData.deviceId=deviceId;
                weightData.broadcastId=deviceInfo.broadcastId;
                
                if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveWeightMeasuredData:)])
                {
                    [self.dataReceiveDelegate bleManagerDidReceiveWeightMeasuredData:weightData];
                }
            }
        }
        else if(currentDeviceType==LS_KITCHEN_SCALE)
        {
            if (characteristicUuid==KITCHENSCALE_INTERMEDIATE_CHARACTER)
            {
                LSKitchenScaleData *kitchenData=[LSBleDataParsingTools parseKitchenMeasurementData:measureData];
                kitchenData.deviceName=deviceInfo.deviceName;
                kitchenData.deviceId=deviceInfo.deviceId;
                
                if([self.dataReceiveDelegate respondsToSelector:@selector(bleManagerDidReceiveKitchenScaleMeasuredData:)])
                {
                    [self.dataReceiveDelegate bleManagerDidReceiveKitchenScaleMeasuredData:kitchenData];
                }
                
            }
        }
    });
}



@end
