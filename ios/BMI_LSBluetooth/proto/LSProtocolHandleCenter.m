//
//  ProtocolHandleCenter.m
//  LSBluetooth-Library
//
//  Created by lifesense on 15/8/5.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import "LSProtocolHandleCenter.h"
#import "LSBleCommandProfiles.h"
#import "LSDeviceProfiles.h"
#import "DispatchBasedTimer.h"




@interface LSProtocolHandleCenter()<LSBleConnectorDelegate>

@property(nonatomic)NSUInteger ENABLE_RECONNECT_COUNT;

@property(nonatomic,strong)LSDeviceInfo *currentConnectedDevice;
@property(nonatomic)ProcessorWorkingStatus currentWorkingStatus;
@property(nonatomic,strong)NSArray *lsDeviceGattServices;

@property(nonatomic)uint32_t randomNumber;
@property(nonatomic)BOOL isReceivedRandomNumber;
@property(nonatomic)BOOL isWrittenBroadcastId;
@property(nonatomic)NSInteger currentDiscoveredLsService;
@property(nonatomic,strong) NSMutableArray *_userNamesArray;
@property(nonatomic,strong) NSMutableDictionary *userListDictionary;
@property(nonatomic,strong)NSTimer *reconnectTimer;
@property(nonatomic)NSUInteger reconnectCount;
@property(nonatomic)NSUInteger localUesrNumber;
@property(nonatomic)NSString *localUserName;
@property(nonatomic,strong)CBPeripheral *reconnectPeripheral;
@property(nonatomic,strong)LSProtocolMessage* currentProtocolMessage;
@property(nonatomic)ProtocolWorkflow currentWorkingflow;
@property(nonatomic,strong)NSMutableArray *currentProtocolMessageQueue;

@property(nonatomic)BOOL doneOfWritePedometerUserInfo;
@property(nonatomic)BOOL doneOfWriteAlarmClock;
@property(nonatomic,strong)NSArray *protocolMessageQueueCopy;
@property(nonatomic,strong)NSMutableArray *deviceInfoCharacteristicQueue;
@property(nonatomic,strong)NSMutableArray *notifyCharacteristicQueue;
@property(nonatomic,strong)CBCharacteristic *currentInfoCharacteristic;
@property(nonatomic,strong)CBCharacteristic *currentNotifyCharacteristic;
@property(nonatomic)BOOL doneOfReadDeviceInfo;
@property(nonatomic)BOOL doneOfSetNotify;
@property(nonatomic,strong)NSArray *lsDeviceCharacteristics;
//new change for version3.0.1
//@property(nonatomic,strong)NSTimer *pairingTimesoutTimer;
@property(nonatomic,strong)DispatchBasedTimer *pairingTimesoutTimer;
@property(nonatomic)NSUInteger pairingTimes;
@end

@implementation LSProtocolHandleCenter


-(instancetype)init
{
    self=[super init];
    if(self)
    {
        //允许重连的最大次数
        self.ENABLE_RECONNECT_COUNT=5;
        self.currentWorkingStatus=ProcessorWorkingStatusFree;
        self.currentConnectedDevice=nil;
        self.reconnectPeripheral=nil;
        self.pairingTimes=70;//70 second
    }
    return self;
}



//执行配对协议流程
-(void)pairingWithDevice:(LSDeviceInfo *)pairingDevice peripheral:(CBPeripheral *)peripheral protocolProcesses:(NSArray *)pairingProtocolQueue count:(NSUInteger)connectCount
{
    if(self.currentWorkingStatus==ProcessorWorkingStatusFree)
    {
        if(pairingDevice && peripheral && pairingProtocolQueue)
        {
            NSString *nameStr=[NSString stringWithFormat:@"pairing device with name:%@",pairingDevice.deviceName];
            [self debugMessage:nameStr debuglevel:DEBUG_LEVEL_GENERAL];
            
            self.doneOfWriteAlarmClock=NO;
            self.doneOfWritePedometerUserInfo=NO;
            
            //发出修改上层管理器的工作状态，信号
            [self updateBleManagerWorkStatus:MANAGER_WORK_STATUS_PAIR];
            
            //修改当前操作的协议模式为，配对模式
            self.currentWorkingStatus=ProcessorWorkingStatusPairing;
            
            self.currentConnectedDevice=pairingDevice;
            self.isReceivedRandomNumber=NO;
            self.isWrittenBroadcastId=NO;
            
            self.bleConnector.bleConnectorDelegate=self;
            _userListDictionary=[[NSMutableDictionary alloc] init];
            
            self.localUesrNumber=0;
            self.localUserName=nil;
            
            self.reconnectPeripheral=peripheral;
            self.reconnectCount=connectCount;
            
            self.currentProtocolMessageQueue=[[NSMutableArray alloc] initWithArray:pairingProtocolQueue];
            
            self.protocolMessageQueueCopy=[[NSMutableArray alloc] initWithArray:pairingProtocolQueue];
            
            self.deviceInfoCharacteristicQueue=[[NSMutableArray alloc] init];
            self.notifyCharacteristicQueue=[[NSMutableArray alloc] init];
            self.doneOfReadDeviceInfo=NO;
            self.doneOfSetNotify=NO;
            
            if(connectCount==0)
            {
//                [self performSelectorOnMainThread:@selector(installPairingTimesoutTimer) withObject:nil waitUntilDone:NO];
                [self installPairingTimesoutTimer];
            }
            
            self.currentProtocolMessage=[self.currentProtocolMessageQueue dequeue];
            self.currentWorkingflow=self.currentProtocolMessage.operatingDirective;
            [self handleProtocolWorkingflow:self.currentWorkingflow];
            
        }
        else
        {
            [self debugMessage:@"Error,failed to pairing device for invalid parameter...." debuglevel:DEBUG_LEVEL_GENERAL];
            [self cancelPairingProcess];
        }
    }
    else
    {
        [self debugMessage:@"Error,failed to pairing device for working status...." debuglevel:DEBUG_LEVEL_GENERAL];
        [self cancelPairingProcess];
    }
}


//执行测量数据上传协议流程
-(void)uploadingWithDevice:(LSDeviceInfo *)pairedDevice peripheral:(CBPeripheral *)peripheral protocolProcesses:(NSArray *)uploadingProtocolQueue count:(NSUInteger)connectCount
{
    if(self.currentWorkingStatus==ProcessorWorkingStatusFree)
    {
        if(pairedDevice && peripheral && uploadingProtocolQueue)
        {
            if([self checkConnectingConstraints:pairedDevice])
            {
                if([pairedDevice.protocolType isEqualToString:@"COMMAND_START"])
                {
                    [self updateBleManagerWorkStatus:MANAGER_WORK_STATUS_CONNECT];
                }
                else
                {
                    //发出修改上层管理器的工作状态，信号
                    [self updateBleManagerWorkStatus:MANAGER_WORK_STATUS_UPLOAD];
                }
                
                NSString *nameStr=[NSString stringWithFormat:@"uploading device with name:%@",pairedDevice.deviceName];
                [self debugMessage:nameStr debuglevel:DEBUG_LEVEL_GENERAL];
                
                //修改当前的协议模式为读取测量数据操作模式
                self.currentWorkingStatus=ProcessorWorkingStatusUploading;
                self.currentConnectedDevice=pairedDevice;
                self.bleConnector.bleConnectorDelegate=self;
                self.doneOfWriteAlarmClock=NO;
                self.doneOfWritePedometerUserInfo=NO;
                
                //连接设备
                self.reconnectPeripheral=peripheral;
                self.reconnectCount=connectCount;
                
                
                self.currentProtocolMessageQueue=[[NSMutableArray alloc] initWithArray:uploadingProtocolQueue];
                
                self.protocolMessageQueueCopy=[[NSMutableArray alloc] initWithArray:uploadingProtocolQueue];
                
                self.deviceInfoCharacteristicQueue=[[NSMutableArray alloc] init];
                self.notifyCharacteristicQueue=[[NSMutableArray alloc] init];
                self.doneOfReadDeviceInfo=NO;
                self.doneOfSetNotify=NO;
                
                self.currentProtocolMessage=[self.currentProtocolMessageQueue dequeue];
                self.currentWorkingflow=self.currentProtocolMessage.operatingDirective;
                [self handleProtocolWorkingflow:self.currentWorkingflow];
            }
            
        }
        else
        {
            [self debugMessage:@"Error,failed to uploading for invalid parameter...." debuglevel:DEBUG_LEVEL_GENERAL];
            [self cancelDataUploadProcess];
        }
    }
    else
    {
        [self debugMessage:@"Error,failed to uploading for working status...." debuglevel:DEBUG_LEVEL_GENERAL];
        [self cancelDataUploadProcess];
    }
}


//中断正在执行的任务
-(void)interruptCurrentTask
{
    if(self.currentWorkingStatus!=ProcessorWorkingStatusFree)
    {
        //断开连接
        [self cancelDeviceConnected];
    }
    else
    {
        [self debugMessage:@"no task interrupt..." debuglevel:DEBUG_LEVEL_GENERAL];
    }
    
    self.currentWorkingStatus=ProcessorWorkingStatusFree;
    [self updateBleManagerWorkStatus:MANAGER_WORK_STATUS_IBLE];
}

//绑定用户编号,A3、A3.1协议专用
-(void)bindingDeviceUsers:(NSUInteger)userNumber userName:(NSString *)name
{
    if(name.length==0 && userNumber>self.currentConnectedDevice.maxUserQuantity)
    {
        [self cancelPairingProcess];
        return;
    }
    else
    {
        self.localUesrNumber=userNumber;
        self.localUserName=name;
        if(self.currentWorkingflow==OPERATING_WRITE_BIND_USER_NUMBER)
        {
            [self handleProtocolWorkingflow:self.currentWorkingflow];
        }
        else
        {
            [self cancelPairingProcess];
        }
    }
}

//版本1.0.8新增接口，写UTC启动测量
-(BOOL)writeCommandToStartMeasuring
{
    if(self.currentWorkingflow==OPERATING_WRITE_START_MEASURE_COMMAND_TO_DEVICE)
    {
        [self debugMessage:@"start measuring....." debuglevel:DEBUG_LEVEL_GENERAL];
        [self handleProtocolWorkingflow:self.currentWorkingflow];
        return YES;
    }
    else
    {
        [self cancelDeviceConnected];
        return NO;
    }
}

#pragma mark - private methods

-(void)debugMessage:(NSString *)msg debuglevel:(DebugLevel)level
{
    [BleDebugLogger object:self printMessage:msg withDebugLevel:level];
}

//修改与设备建立的当前连接状态
-(void)updateDeviceConnectStatus:(DeviceConnectState)connectState
{
    
    NSString *connectName=nil;
    if(self.currentWorkingStatus==ProcessorWorkingStatusUploading)
    {
        connectName=self.currentConnectedDevice.broadcastId;
        
    }
    else  connectName=self.currentConnectedDevice.deviceName;
    
    if([self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidConnectStatusChange:broadcastId:)])
    {
        [self.bleProtocolDelegate bleProtocolDidConnectStatusChange:connectState broadcastId:connectName];
    }
    
}

/*
 *  修改上层管理器的工作状态
 */
-(void)updateBleManagerWorkStatus:(NSInteger)newStatus
{
    if(self.bleProtocolDelegate && [self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidWorkStatusChange:)])
    {
        [self.bleProtocolDelegate bleProtocolDidWorkStatusChange:newStatus];
    }
}

/*
 * 检查当前进行连接的外围信息是否附全连接条件，
 */
-(BOOL)checkConnectingConstraints:(LSDeviceInfo *)checkingDevice
{
    NSString *errorMsg=nil;
    if(checkingDevice)
    {
        NSInteger lsService=[LSDeviceProfiles getServiceUuidByDeviceType:checkingDevice.deviceType protocolType:checkingDevice.protocolType];
        
        if(lsService==KITCHENSCALE_SERVICE_UUID
           ||lsService==BLOODPRESSURE_COMMAND_START_SERVICE_UUID
           ||lsService==GENERIC_FAT_SCALE_SERVICE_UUID)
        {
            return  YES;
        }
        if(checkingDevice.password!=0 && lsService!=0 )
        {
            return YES;
        }
        else
        {
            errorMsg=[NSString stringWithFormat:@"Error ! failed to connect peripheral,for password(%@),deviceType(%d),broadcastId(%@),service(%ld),protocol(%@)",checkingDevice.password,checkingDevice.deviceType,checkingDevice.broadcastId,(long)lsService,checkingDevice.protocolType];
            [self debugMessage:errorMsg debuglevel:DEBUG_LEVEL_GENERAL];
            
            return NO;
        }
    }
    else
    {
        errorMsg=[NSString stringWithFormat:@"Error ! failed to connect peripheral,for null"];
        [self debugMessage:errorMsg debuglevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
}

-(NSData *)getDefaultBroadcastId
{
    uint8_t value[20]={0};
    value[0]=SIGNATURE_COMMAND;
    // set default broadcast id
    uint32_t utc = [LSFormatConverter currentUTC];
    value[1]=utc&0xff;
    utc= utc>>8;
    value[2]= utc&0xff;
    utc=utc>>8;
    value[3]=utc&0xff;
    utc=utc>>8;
    value[4]=utc&0xff;
    
    NSString *tempBroadcastId=nil;
    for(int i = 0;i<4;i++)
    {
        NSString *temp = nil;
        if (value[i+1]<16)
        {
            temp = [NSString stringWithFormat:@"0%x",value[i+1]];
        }
        else  temp = [NSString stringWithFormat:@"%x",value[i+1]];
        
        if (!tempBroadcastId)
        {
            tempBroadcastId = temp;
        }
        else
        {
            tempBroadcastId = [tempBroadcastId stringByAppendingString:temp];
        }
    }
    self.currentConnectedDevice.broadcastId=[tempBroadcastId uppercaseString];
    
    NSData *broadcastIdData=[NSData dataWithBytes:value length:5];
    
    return broadcastIdData;
    
}


-(void)cancelPairingTimesoutTimer
{
    [BleDebugLogger object:self printMessage:@"cancel pairing times out timer..." withDebugLevel:DEBUG_LEVEL_GENERAL];
    if(self.pairingTimesoutTimer)
    {
        [self.pairingTimesoutTimer cancel];
        self.pairingTimesoutTimer=nil;
    }
}

-(void)installPairingTimesoutTimer
{
    [BleDebugLogger object:self printMessage:@"set up pairing times out timer..." withDebugLevel:DEBUG_LEVEL_GENERAL];
    if(self.pairingTimesoutTimer)
    {
        [self.pairingTimesoutTimer cancel];
        self.pairingTimesoutTimer=nil;
    }
    //install pairing timeout timer
//    self.pairingTimesoutTimer= [NSTimer scheduledTimerWithTimeInterval:self.pairingTimes target:self selector:@selector(cancelPairingForTimesout) userInfo:nil repeats:NO];
    self.pairingTimesoutTimer = [DispatchBasedTimer timerWithDispatchQueue:self.bleConnector.dispatchQueue
                                                     timeoutInMilliSeconds:self.pairingTimes * 1000
                                                                  andBlock:^{
                                                                      [self cancelPairingForTimesout];
                                                                  }];
}

-(void)releaseResources
{
    self.localProductUserInfo=nil;
    self.pedometerUserInfo=nil;
    self.alarmClock=nil;
    self.vibrationVoice=nil;
    self.reconnectCount=0;
    self.currentProtocolMessageQueue=nil;
    
    self.protocolMessageQueueCopy=nil;
    
    self.deviceInfoCharacteristicQueue=nil;
    self.notifyCharacteristicQueue=nil;
    self.currentInfoCharacteristic=nil;
    self.currentNotifyCharacteristic=nil;
    self.lsDeviceCharacteristics=nil;
}


#pragma mark - about reconnect peripheral
/*
 *  若第一次连接失败，则尝试5次重新连接，若5次连接失败，则返回结果
 */
-(BOOL)reconnectPeripheral:(CBPeripheral *)peripheral
{
    NSString *msg=nil;
    if(peripheral)
    {
        //debug message
        msg=[NSString stringWithFormat:@"try to reconnect peripheral,count :(%lu)",(unsigned long)self.reconnectCount];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        
        self.reconnectCount++;
        if(self.currentWorkingStatus==ProcessorWorkingStatusPairing)
        {
            self.currentWorkingStatus=ProcessorWorkingStatusFree;
            [self pairingWithDevice:self.currentConnectedDevice peripheral:peripheral protocolProcesses:self.protocolMessageQueueCopy count:self.reconnectCount];
        }
        else if(self.currentWorkingStatus==ProcessorWorkingStatusUploading)
        {
            self.currentWorkingStatus=ProcessorWorkingStatusFree;
            [self uploadingWithDevice:self.currentConnectedDevice peripheral:peripheral protocolProcesses:self.protocolMessageQueueCopy count:self.reconnectCount];
        }
        else
        {
            [self cancelDeviceConnected];
        }
        
        
        return YES;
    }
    else
    {
        self.protocolMessageQueueCopy=nil;
        self.reconnectPeripheral=nil;
        //debug message
        msg=[NSString stringWithFormat:@"Error!failed to reconnect peripheral with count :(%lu)",(unsigned long)self.reconnectCount];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        
        [self cancelDeviceConnected];
        
        return NO;
        
    }
}




#pragma mark - about read device info

/*
 *  读取设备信息
 */
-(void)handleReadDeviceInfoWithCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *msg=nil;
    if(characteristic)
    {
        msg=[NSString stringWithFormat:@"current read device info with characteristic %@",characteristic.UUID.UUIDString];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
        [self.bleConnector readValueForCharacteristic:characteristic];
    }
    else
    {
        msg=[NSString stringWithFormat:@"failed to read device info with characteristic, is nil"];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        [self cancelDeviceConnected];
    }
}

/*
 *  处理由设备发送上来的设备信息
 */
-(void)handleSaveDeviceInfoFromCharacteristic:(CBCharacteristic*)characteristic
{
    
    uint16_t uuidValue = [LSFormatConverter uintValueWithCBUUID:characteristic.UUID];
    if(uuidValue==DEVICE_MANUFACTURER_CHARACTER)
    {
        NSString *manufacturerName = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        self.currentConnectedDevice.manufactureName=manufacturerName;
    }
    else if (uuidValue==DEVICE_MODEL_NUMBER_CHARACTER)
    {
        NSString *modelNumber= [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        self.currentConnectedDevice.modelNumber=[modelNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    else if(uuidValue==DEVICE_SERIAL_NUMBER_CHARACTER)
    {
        NSString *serialNumber = [[NSString alloc]initWithData:characteristic.value encoding:NSASCIIStringEncoding];
        if ([serialNumber length]>12)
        {
            
            self.currentConnectedDevice.deviceId = [[serialNumber substringWithRange:NSMakeRange(0, 12)] uppercaseString];
        }
        else
        {
            self.currentConnectedDevice.deviceId  = [serialNumber lowercaseString];
        }
        self.currentConnectedDevice.deviceSn = [LSFormatConverter translateDeviceIdToSN:self.currentConnectedDevice.deviceId];
    }
    else if(uuidValue==DEVICE_SOFTWARE_VERSION_CHARACTER)
    {
        NSString *softwareVersion = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        self.currentConnectedDevice.softwareVersion = [softwareVersion stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    else if(uuidValue==DEVICE_HARDWARE_VERSION_CHARACTER)
    {
        NSString *hardwareVersion = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        self.currentConnectedDevice.hardwareVersion = [hardwareVersion stringByReplacingOccurrencesOfString:@" " withString:@""];
    }
    else if(uuidValue==DEVICE_FIRMWARE_VERSION_CHARACTER)
    {
        NSString *firmwareVersion = [[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        self.currentConnectedDevice.firmwareVersion = [firmwareVersion stringByReplacingOccurrencesOfString:@" " withString:@""];
        self.currentConnectedDevice.maxUserQuantity = [[firmwareVersion substringFromIndex:2] integerValue];
    }
}

#pragma mark - about paired results and upload results process

/*
 *   数据上传结束处理
 */
-(void)handleDataUploadResults:(NSInteger)completionFlag
{
    self.currentWorkingStatus=ProcessorWorkingStatusFree;
    if([self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidDataReceiveComplete:deviceId:)])
    {
        [self.bleProtocolDelegate bleProtocolDidDataReceiveComplete:completionFlag deviceId:self.currentConnectedDevice.deviceId];
    }
}

/*
 *  对配对结果进行处理
 */
-(void)handlePairedResults:(LSDeviceInfo *)pairedLsDevice pairedState:(NSInteger)pairedState
{
    self.userListDictionary=nil;
    self.currentWorkingStatus=ProcessorWorkingStatusFree;
    
    if([self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidPairedResults:pairedStatus:)])
    {
        [self.bleProtocolDelegate bleProtocolDidPairedResults:pairedLsDevice pairedStatus:pairedState];
    }
}


#pragma mark - about cancel device connect

/*
 * 断开设备连接
 */
-(void)cancelDeviceConnected
{
    //disconnect device
    if(self.bleConnector)
    {
        [self.bleConnector disConnectPeripheral];
    }
    
    if(self.currentWorkingStatus==ProcessorWorkingStatusPairing
       && self.currentWorkingflow!=OPERATING_PAIRED_RESULTS_PROCESS)
    {
        [self cancelPairingProcess];
    }
    else if (self.currentWorkingStatus==ProcessorWorkingStatusUploading
             && self.currentWorkingflow!=OPERATING_UPLOADED_RESULTS_PROCESS)
    {
        [self cancelDataUploadProcess];
    }
}

-(void)cancelPairingForTimesout
{
    NSString *errorMsg=[NSString stringWithFormat:@"Pairing times out,failed to pair device on step=%@",[LSProtocolWorkflow enumToString:self.currentWorkingflow]];
    [self debugMessage:errorMsg debuglevel:DEBUG_LEVEL_GENERAL];
    //disconnect device
    if(self.bleConnector)
    {
        [self.bleConnector disConnectPeripheral];
    }
    [self handlePairedResults:nil pairedState:PAIRED_FAILED];
}

/*
 *  若在配对过程中出现错误，则取消这一次配对，返回配对结果
 */
-(void)cancelPairingProcess
{
    NSString *errorMsg=[NSString stringWithFormat:@"Error,failed to pair device on step=%@",[LSProtocolWorkflow enumToString:self.currentWorkingflow]];
    [self debugMessage:errorMsg debuglevel:DEBUG_LEVEL_GENERAL];
    
    [self handlePairedResults:nil pairedState:PAIRED_FAILED];
    
    [self cancelPairingTimesoutTimer];
}

/*
 *  若测量数据在上传过程中，出现错误，则停止测量数据上传流程
 */

-(void)cancelDataUploadProcess
{
    NSString *errorMsg=[NSString stringWithFormat:@"Error,failed to uploading data on step=%@",[LSProtocolWorkflow enumToString:self.currentWorkingflow]];
    [self debugMessage:errorMsg debuglevel:DEBUG_LEVEL_GENERAL];
    
    [self handleDataUploadResults:DATA_UPLOAD_FAILED];
}

#pragma mark - about set notify for characteristic

-(void)handleSetNotifyWithCharacteristic:(CBCharacteristic *)notifyCharacteristic
{
    NSString *msg=nil;
    if(notifyCharacteristic)
    {
        msg=[NSString stringWithFormat:@"try to set notify with characteristic:%@",notifyCharacteristic.UUID.UUIDString];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
        [self.bleConnector setNotifyValue:YES
                        forCharacteristic:notifyCharacteristic];
    }
    else
    {
        msg=[NSString stringWithFormat:@"failed to set notify with characteristic:nil"];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        [self cancelDeviceConnected];
    }
}

#pragma mark - about discover characteristic by service type

/*
 *  从一组服务号中解析当前连接的乐心设备的服务号
 */
-(NSInteger)parsingDiscoveredLsService:(NSArray *)gattServices
{
    NSString *msg=nil;
    if([gattServices count])
    {
        NSInteger discoveredService=[LSDeviceProfiles getServiceUuidByDeviceType:self.currentConnectedDevice.deviceType protocolType:self.currentConnectedDevice.protocolType];
        for (CBService *service in gattServices)
        {
            uint16_t serviceValue=[LSFormatConverter uintValueWithCBUUID:service.UUID];
            if(serviceValue==discoveredService)
            {
                //debug message
                msg=[NSString stringWithFormat:@"current discovered service=%x ; protocol type=%@",serviceValue,self.currentConnectedDevice.protocolType];
                [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
                return discoveredService;
            }
            if(serviceValue==GENERIC_FAT_SCALE_SERVICE_UUID)
            {
                msg=[NSString stringWithFormat:@"current discovered service=%x ; protocol type=%@",serviceValue,self.currentConnectedDevice.protocolType];
                [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
                return GENERIC_FAT_SCALE_SERVICE_UUID;
            }
        }
        
        msg=[NSString stringWithFormat:@"failed to parsing discovered services: %lx",(long)discoveredService];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        return 0;
    }
    else return 0;
}

/*
 *  根据服务号，发现其特有的特征号
 */
-(void)discoverCharacteristicForServiceType:(NSInteger)serviceType
{
    for(CBService *service in self.lsDeviceGattServices)
    {
        uint16_t serviceValue=[LSFormatConverter uintValueWithCBUUID:service.UUID];
        if(serviceValue==serviceType)
        {
            [self.bleConnector discoverCharacteristicsForService:service];
            break;
        }
        
    }
}


#pragma mark - about on characteristic change value

/*
 *  处理由设备发送上来的数据信息
 */
-(void)handleUploadMessageForCharacteristic:(CBCharacteristic*)characteristic
{
    NSString *msg=nil;
    //获取命令字节数据
    uint8_t *byte = (uint8_t*)[characteristic.value bytes];
    uint8_t command = *byte;
    byte++;
    
    if(command==PASSWORD_COMMAND)
    {
        //处理接收到的密码
        uint32_t password=*(uint32_t*)byte;
        self.currentConnectedDevice.password =[LSFormatConverter uint32toHexString:password] ;
        
        msg=[NSString stringWithFormat:@"receive password (%@)",self.currentConnectedDevice.password];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
        
        //enter next step
        [self handleProtocolWorkingflow:[self getNextWorkingflow]];
        
    }
    else if(command==RANDOM_NUMBER_COMMAND)
    {
        //处理接收到的随机数
        self.randomNumber= *(uint32_t*)byte;
        self.isReceivedRandomNumber=YES;
        
        msg=[NSString stringWithFormat:@"receive randomnumber (%lu)",(unsigned long)self.randomNumber];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
        
        if(self.currentWorkingStatus==ProcessorWorkingStatusPairing)
        {
            if(self.isWrittenBroadcastId && self.isReceivedRandomNumber)
            {
                [self handleProtocolWorkingflow:[self getNextWorkingflow]];
            }
        }
        else if (self.currentWorkingStatus==ProcessorWorkingStatusUploading)
        {
            if(self.currentWorkingflow==OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS)
            {
                [self handleProtocolWorkingflow:[self getNextWorkingflow]];
            }
        }
    }
    else if(command==USER_NUMBER_AND_NAME_COMMAND)
    {
        //处理在配对过程中，由设备发送上来的用户编号与用户名列表
        [self handleReceivedUserNumberList:characteristic.value];
    }
    else if(command==UPDATE_USERINFO_COMMAND)
    {
        //处理在读取测量过程中，由设备发送上来的产品用户信息
        [self handleReceivedUserInfoFromPeripheral:characteristic.value];
    }
    else
    {
        
        [self debugMessage:@"measuring data start uploading...." debuglevel:DEBUG_LEVEL_GENERAL];
        //处理接收到的测量数据,返回上层管理器
        if([self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidReceiveMeasuredData:fromCharacteristic:device:)])
        {
            uint16_t characteristicUuid=[LSFormatConverter uintValueWithCBUUID:characteristic.UUID];
            [self.bleProtocolDelegate bleProtocolDidReceiveMeasuredData:characteristic.value
                                                             fromCharacteristic:characteristicUuid
                                                                 device:self.currentConnectedDevice];
        }
    }
}

/*
 *  处理接收到的用户信息
 */
-(void)handleReceivedUserInfoFromPeripheral:(NSData *)userInfoData
{
    uint8_t *byte = (uint8_t*)[userInfoData bytes];
    if (*byte != UPDATE_USERINFO_COMMAND)
    {
        return;
    }
    LSProductUserInfo *userInfo=[[LSProductUserInfo alloc] init];
    byte++;
    
    uint8_t flags = *byte;
    byte++;
    userInfo.userNumber = *byte;
    byte++;
    
    if (flags&0x01)
    {
        uint8_t sexValue= *byte;
        if(sexValue==1)
        {
            userInfo.sex =SEX_MALE;
        }
        else userInfo.sex=SEX_FEMALE;
        byte++;
    }
    
    if ((flags>>1)&0x01) {
        userInfo.age = *byte;
        byte++;
    }
    
    if ((flags>>2)&0x01) {
        uint16_t tempHeight = *(byte+1);
        tempHeight = (tempHeight<<8)|(*byte);
        userInfo.height = [LSBleDataParsingTools translateToSFloat:tempHeight];
        byte+=2;
    }
    
    if ((flags>>3) & 0x01)
    {
        userInfo.athleteLevel = *byte;
        byte++;
    }
    if ((flags>>4)&0x01) {
        switch (*byte) {
            case 0:
                userInfo.unit = UNIT_KG;
                break;
            case 1:
                userInfo.unit = UNIT_LB;
                break;
            case 2:
                userInfo.unit = UNIT_ST;
                break;
            default:
                break;
        }
    }
    //debug message
    NSString *msg=[NSString stringWithFormat:@"receive user info :%@",[LSFormatConverter dictionaryWithProperty:userInfo]];
    [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
    
    if([self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidDiscoverdProductUserInfo:)])
    {
        [self.bleProtocolDelegate bleProtocolDidDiscoverdProductUserInfo:userInfo];
    }
}

/*
 *  配对过程中，处理接收的用户编号与用户名列表
 */
-(void)handleReceivedUserNumberList:(NSData *)userlistData
{
    
    uint8_t *byte = (uint8_t*)[userlistData bytes];
    byte++;
    uint8_t userNumberFlag = *byte;
    byte++;

    NSData *dataTemp = [NSData dataWithBytes:byte length:16];
    NSString *nameString =[LSFormatConverter formattingValidUTF8:dataTemp];
    if(!nameString)
    {
        nameString=@"unknowName";
    }
    
    [self.userListDictionary setObject:nameString forKey:@(userNumberFlag)];

    if(self.currentConnectedDevice.deviceType==LS_SPHYGMOMETER || self.currentConnectedDevice.deviceType==LS_FAT_SCALE)
    {
        NSString *msg=nil;
        if(self.currentConnectedDevice.deviceType==LS_SPHYGMOMETER)
        {
            if(self.currentConnectedDevice.maxUserQuantity==0)
            {
                self.currentConnectedDevice.maxUserQuantity=2;
            }
        }
        
        if(userNumberFlag ==self.currentConnectedDevice.maxUserQuantity)
        {
            //debug message
            msg=[NSString stringWithFormat:@"receive user number list: %@",self.userListDictionary];
            [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
            
            if([self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidDiscoverdUserlist:)])
            {
                [self.bleProtocolDelegate bleProtocolDidDiscoverdUserlist:self.userListDictionary];
            }
        }
        else if(userNumberFlag >self.currentConnectedDevice.maxUserQuantity)
        {
            //debug message
            msg=[NSString stringWithFormat:@"Failed to parse user number list ,device type(%d),maxUserQuantity (%lu),current user number (%d)",self.currentConnectedDevice.deviceType,self.currentConnectedDevice.maxUserQuantity,userNumberFlag];
            [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        }
    }
    
}

#pragma mark - about write command to peripheral and callback process

/*
 *  写命令到设备
 */
-(void)handleWriteCommandToPeripheral:(NSData *)valueData
{
    NSString *msg=nil;
    if(valueData)
    {
        for (CBCharacteristic *characteristic in self.lsDeviceCharacteristics)
        {
            uint16_t downloadCharacter=[LSFormatConverter uintValueWithCBUUID:characteristic.UUID];
            if (downloadCharacter==DEVICE_DOWNLOAD_CHARACTER)
            {
                msg=[NSString stringWithFormat:@"write command with data:%@",[valueData description]];
                [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
                [self.bleConnector writeValue:valueData forCharacteristic:characteristic];
                break;
            }
        }
    }
    else
    {
        //debug message
        NSString *commandValue=[[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
         msg=[NSString stringWithFormat:@"Failed to write command to peripheral,because of command error-(%@)",commandValue];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        
        [self cancelDeviceConnected];
    }
    
}


//命令定完回调处理
-(void)handleCallbackEventsForCommandWriteSuccess
{
    if(self.currentWorkingflow==OPERATING_WRITE_BROADCAST_ID)
    {
        self.isWrittenBroadcastId=YES;
        if(self.isReceivedRandomNumber && self.isWrittenBroadcastId)
        {
            [self handleProtocolWorkingflow:[self getNextWorkingflow]];
        }
        
    }
    else if (self.currentWorkingflow==OPERATING_WRITE_XOR_RESULTS)
    {
        ProtocolWorkflow nextWoringkflow=[self getNextWorkingflow];
        if(nextWoringkflow==OPERATING_WRITE_BIND_USER_NUMBER)
        {
            //执行A3协议配对流程
            [self debugMessage:@"waiting for write user id...." debuglevel:DEBUG_LEVEL_GENERAL];
            self.currentWorkingflow=nextWoringkflow;
        }
        else
        {
            //执行A2协议配对流程
            [self handleProtocolWorkingflow:nextWoringkflow];
        }
    }
    else if (self.currentWorkingflow==OPERATING_WRITE_USER_INFO
             ||self.currentWorkingflow==OPERATING_WRITE_VIBRATION_VOICE)
    {
        [self handleWriteSuccessForUserInfo];
        [self handleProtocolWorkingflow:[self getNextWorkingflow]];
        
    }
    else if (self.currentWorkingflow==OPERATING_WRITE_ALARM_CLOCK)
    {
        self.doneOfWriteAlarmClock=YES;
        [self handleWriteSuccessForUserInfo];
        [self handleProtocolWorkingflow:[self getNextWorkingflow]];
    }
    else if(self.currentWorkingflow==OPERATING_WRITE_CURRENT_STATE_TO_PEDOMETER
            ||self.currentWorkingflow==OPERATING_WRITE_TARGET_STATE_TO_PEDOMETER
            ||self.currentWorkingflow==OPERATING_WRITE_UNIT_CONVERSION_TO_PEDOMETER
            ||self.currentWorkingflow==OPERATING_WRITE_USER_MESSAGE_TO_PEDOMETER)
    {
        self.doneOfWritePedometerUserInfo=YES;
        [self handleWriteSuccessForUserInfo];
        [self handleProtocolWorkingflow:[self getNextWorkingflow]];
    }
    else if(self.currentWorkingflow==OPERATING_WRITE_UTC_TIME)
    {
        if([PROTOCOL_TYPE_BLOOD_PRESSURE_COMMAND_START isEqualToString:self.currentConnectedDevice.protocolType])
        {
            self.currentWorkingflow=[self getNextWorkingflow];
        }
        else
        {
            [self handleProtocolWorkingflow:[self getNextWorkingflow]];
        }
    }
    else if (self.currentWorkingflow==OPERATING_WRITE_DISCONNECT)
    {
        //waiting for device disconnect
        self.currentWorkingflow=[self getNextWorkingflow];
    }
    else
    {
        [self handleProtocolWorkingflow:[self getNextWorkingflow]];
    }
    
}

/*
 *  处理用户信息设置成功后的返回通知
 */
-(void)handleWriteSuccessForUserInfo
{
    WriteInfoType tempInfoType=WriteInfoTypeUnknown;
    NSString *deviceId=nil;
    NSString *memberId=nil;
    
    if(self.currentConnectedDevice.deviceType==LS_FAT_SCALE && [self.currentConnectedDevice.deviceId isEqualToString:self.localProductUserInfo.deviceId])
    {
        tempInfoType=WRITE_PRODUCT_USER_INFO;
        deviceId=self.localProductUserInfo.deviceId;
        memberId=self.localProductUserInfo.memberId;
    }
    else if(self.currentConnectedDevice.deviceType==LS_PEDOMETER && [self.currentConnectedDevice.deviceId isEqualToString:self.pedometerUserInfo.deviceId])
    {
        if(self.doneOfWritePedometerUserInfo)
        {
            self.doneOfWritePedometerUserInfo=NO;
            tempInfoType=WRITE_PEDOMETER_USER_INFO;
            deviceId=self.pedometerUserInfo.deviceId;
            memberId=self.pedometerUserInfo.memberId;
        }
        if(self.doneOfWriteAlarmClock)
        {
            self.doneOfWriteAlarmClock=NO;
            tempInfoType=WRITE_ALARM_CLOCK;
            deviceId=self.pedometerUserInfo.deviceId;
            memberId=self.pedometerUserInfo.memberId;
        }
        
    }
    
    
    //返回通知
    if([self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidWriteSuccessForUserInfo:memberId:writeInfoType:)])
    {
        
        [self.bleProtocolDelegate bleProtocolDidWriteSuccessForUserInfo:deviceId memberId:memberId writeInfoType:tempInfoType];
    }
    
}


#pragma mark - protocol working flow handler center

-(CBCharacteristic *)getNextNotifyCharacteristic
{
    CBCharacteristic *nextNotifyCharacteristic=nil;
    if([self.notifyCharacteristicQueue count])
    {
        NSString *msg=nil;
        [self.notifyCharacteristicQueue removeObject:self.currentNotifyCharacteristic];
        self.currentNotifyCharacteristic=[self.notifyCharacteristicQueue peekqueue];
        if(self.currentNotifyCharacteristic)
        {
            nextNotifyCharacteristic=self.currentNotifyCharacteristic;
            msg=[NSString stringWithFormat:@"next set notify characteristic is :%@",nextNotifyCharacteristic.UUID.UUIDString];
            [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
        }
        else
        {
            nextNotifyCharacteristic=nil;
            self.doneOfSetNotify=YES;
            msg=[NSString stringWithFormat:@"Done, no next characteristic to set notify..."];
            [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        }
        
    }
    
    
    return nextNotifyCharacteristic;
}

-(CBCharacteristic *)getNextDeviceInfoCharacteristic
{
    CBCharacteristic *nextInfoCharacteristic=nil;
    if([self.deviceInfoCharacteristicQueue count])
    {
        NSString *msg=nil;
        [self.deviceInfoCharacteristicQueue removeObject:self.currentInfoCharacteristic];
        self.currentInfoCharacteristic=[self.deviceInfoCharacteristicQueue peekqueue];
        if(self.currentInfoCharacteristic)
        {
            nextInfoCharacteristic=self.currentInfoCharacteristic;
            msg=[NSString stringWithFormat:@"next read device info characteristic is :%@",nextInfoCharacteristic.UUID.UUIDString];
            [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
        }
        else
        {
            nextInfoCharacteristic=nil;
            self.doneOfReadDeviceInfo=YES;
            msg=[NSString stringWithFormat:@"Done, no next device info characteristic to read..."];
            [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        }
        
    }
    
    return nextInfoCharacteristic;
}

/*
 * 获取下一步操作
 */
-(ProtocolWorkflow)getNextWorkingflow
{
    if([self.currentProtocolMessageQueue count])
    {
        [self.currentProtocolMessageQueue removeObject:self.currentProtocolMessage];
        self.currentProtocolMessage=[self.currentProtocolMessageQueue peekqueue];
        if(self.currentProtocolMessage)
        {
            self.currentWorkingflow=self.currentProtocolMessage.operatingDirective;
            NSString *msg=[NSString stringWithFormat:@"next step is :%@",[LSProtocolWorkflow enumToString:self.currentWorkingflow]];
            [self debugMessage:msg debuglevel:DEBUG_LEVEL_SUPREME];
            return self.currentWorkingflow;
        }
        else
        {
             [self debugMessage:@"Done! no next operating directive" debuglevel:DEBUG_LEVEL_GENERAL];
            return OPERATING_UNKNOWN;
        }
        
    }
    else return OPERATING_UNKNOWN;
}

/*
 *  根据当前的操作指令执行相应的处理流程
 */
-(void)handleProtocolWorkingflow:(ProtocolWorkflow)workflow
{
    NSData *tempCommandData=nil;
    switch (workflow)
    {
        case OPERATING_CONNECT_DEVICE:
        {
            [self debugMessage:@"try to connect device...." debuglevel:DEBUG_LEVEL_SUPREME];
            [self.bleConnector connectPeripheral:self.reconnectPeripheral];
        }break;
        case OPERATING_READ_DEVICE_INFO:
        {
            if([self.deviceInfoCharacteristicQueue count])
            {
                self.currentInfoCharacteristic=self.deviceInfoCharacteristicQueue.peekqueue;
                [self handleReadDeviceInfoWithCharacteristic:self.currentInfoCharacteristic];
            }
            else [self cancelDeviceConnected];
        }break;
        case OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS:
        {
            if([self.notifyCharacteristicQueue count])
            {
                self.currentNotifyCharacteristic=self.notifyCharacteristicQueue.peekqueue;
                [self handleSetNotifyWithCharacteristic:self.currentNotifyCharacteristic];
            }
            else [self cancelDeviceConnected];
        }break;
        case OPERATING_SET_NOTIFY_FOR_KITCHEN_SCALE:
        {
            [self debugMessage:@"set notify for kitchen scale" debuglevel:DEBUG_LEVEL_GENERAL];
            
        }break;
        case OPERATING_RECEIVE_PASSWORD:
        {
            [self handleProtocolWorkingflow:[self getNextWorkingflow]];
            
        }break;
        case OPERATING_WRITE_BROADCAST_ID:
        {
            if(self.currentWorkingStatus==ProcessorWorkingStatusPairing)
            {
                //判断是否有自定义的广播ID
                if(self.currentConnectedDevice.broadcastId.length)
                {
                    tempCommandData=[LSBleCommandProfiles getBroadcastIdCommand:self.currentConnectedDevice.broadcastId];
                }
                else
                {
                    //没有自定义的广播ID,则采用设置默认的广播ID
                    tempCommandData=[self getDefaultBroadcastId];
                }
                
                [self handleWriteCommandToPeripheral:tempCommandData];
                return;
            }
            else if(self.currentWorkingStatus==ProcessorWorkingStatusUploading)
            {
                //A3.1协议，在测量数据上传协议流程，才有写广播ID这一步
                if(self.currentConnectedDevice.broadcastId.length)
                {
                    tempCommandData=[LSBleCommandProfiles getBroadcastIdCommand:self.currentConnectedDevice.broadcastId];
                    [self handleWriteCommandToPeripheral:tempCommandData];
                }
                else [self cancelDeviceConnected];
            }
            
        }break;
        case OPERATING_RECEIVE_RANDOM_NUMBER:
        {
            [self handleProtocolWorkingflow:[self getNextWorkingflow]];
        }break;
        case OPERATING_WRITE_XOR_RESULTS:
        {
            if(self.currentConnectedDevice.password.length)
            {
                tempCommandData=[LSBleCommandProfiles getXorResultsCommand:self.currentConnectedDevice.password randomNumber:self.randomNumber];
                [self handleWriteCommandToPeripheral:tempCommandData];
            }
            else [self cancelDeviceConnected];
        }break;
        case OPERATING_WRITE_BIND_USER_NUMBER:
        {
            tempCommandData=[LSBleCommandProfiles getBindingUserNameCommand:self.localUesrNumber name:self.localUserName];
            self.currentConnectedDevice.deviceUserNumber=self.localUesrNumber;
            [self handleWriteCommandToPeripheral:tempCommandData];
        }break;
        case OPERATING_WRITE_START_MEASURE_COMMAND_TO_DEVICE:
        {
            [self handleProtocolWorkingflow:[self getNextWorkingflow]];
        }break;
        case OPERATING_WRITE_USER_INFO:
        {
            tempCommandData=self.currentProtocolMessage.commandData;
            
            if(self.currentWorkingStatus==ProcessorWorkingStatusPairing)
            {
                //配对过程中设置用户信息
                if(tempCommandData.length)
                {
                    self.localProductUserInfo.userNumber=self.localUesrNumber;
                    tempCommandData=[self.localProductUserInfo userInfoCommandData];
                }
                else
                {
                    //若在配对过程中没有用户信息可写，则填写默认的用户信息
                    uint8_t value[15] = {0};
                    value[0] = CLAIM_USERNUMBER_COMMAND;
                    int count = 1;
                    //没有用户信息可写，配对过程中直接写命令，数据上传过程中，直接跳过
                    value[count++] = 0;   //标记位
                    value[count++] = self.localUesrNumber;     //userNumber
                    tempCommandData =[NSData dataWithBytes:value length:count];
                }
                [self handleWriteCommandToPeripheral:tempCommandData];
            }
            else
            {
                 //测量数据上传过程中设置用户信息
               if(tempCommandData==nil || tempCommandData.length==0)
                {
                    [self handleProtocolWorkingflow:[self getNextWorkingflow]];
                }
               else
               {
                   [self handleWriteCommandToPeripheral:tempCommandData];
               }
            }
        }break;
        case OPERATING_WRITE_ALARM_CLOCK:
        {
            tempCommandData=self.currentProtocolMessage.commandData;
           if(tempCommandData==nil || tempCommandData.length==0)
            {
                [self handleProtocolWorkingflow:[self getNextWorkingflow]];
            }
            else
            {
                [self handleWriteCommandToPeripheral:tempCommandData];
            }
        }break;
        case OPERATING_WRITE_VIBRATION_VOICE:
        {
            tempCommandData=self.currentProtocolMessage.commandData;
            if(tempCommandData==nil || tempCommandData.length==0)
            {
                [self handleProtocolWorkingflow:[self getNextWorkingflow]];
            }
            else
            {
                [self handleWriteCommandToPeripheral:tempCommandData];
            }
        }break;
        case OPERATING_WRITE_USER_MESSAGE_TO_PEDOMETER:
        {
            tempCommandData=self.currentProtocolMessage.commandData;
            if(tempCommandData==nil || tempCommandData.length==0)
            {
                [self handleProtocolWorkingflow:[self getNextWorkingflow]];
            }
            else
            {
                [self handleWriteCommandToPeripheral:tempCommandData];
            }
        }break;
        case OPERATING_WRITE_CURRENT_STATE_TO_PEDOMETER:
        {
            tempCommandData=self.currentProtocolMessage.commandData;
            if(tempCommandData==nil || tempCommandData.length==0)
            {
                [self handleProtocolWorkingflow:[self getNextWorkingflow]];
            }
            else
            {
                [self handleWriteCommandToPeripheral:tempCommandData];
            }
        }break;
        case OPERATING_WRITE_TARGET_STATE_TO_PEDOMETER:
        {
            tempCommandData=self.currentProtocolMessage.commandData;
            if(tempCommandData==nil || tempCommandData.length==0)
            {
                [self handleProtocolWorkingflow:[self getNextWorkingflow]];
            }
            else
            {
                [self handleWriteCommandToPeripheral:tempCommandData];
            }
        }break;
        case OPERATING_WRITE_UNIT_CONVERSION_TO_PEDOMETER:
        {
            tempCommandData=self.currentProtocolMessage.commandData;
            if(tempCommandData==nil || tempCommandData.length==0)
            {
                [self handleProtocolWorkingflow:[self getNextWorkingflow]];
            }
            else
            {
                [self handleWriteCommandToPeripheral:tempCommandData];
            }
        }break;
            
        case OPERATING_WRITE_UTC_TIME:
        {
            tempCommandData=self.currentProtocolMessage.commandData;
            [self handleWriteCommandToPeripheral:tempCommandData];
        }break;
        case OPERATING_WRITE_DISCONNECT:
        {
            tempCommandData=self.currentProtocolMessage.commandData;
            [self handleWriteCommandToPeripheral:tempCommandData];
        }break;
        case OPERATING_PAIRED_RESULTS_PROCESS:
        {
            [self debugMessage:@"Done ! successfully paired...." debuglevel:DEBUG_LEVEL_GENERAL];
            [self cancelPairingTimesoutTimer];
            [self.bleConnector disConnectPeripheral];
            
            [self releaseResources];
            //返回配对结果
            [self handlePairedResults:self.currentConnectedDevice pairedState:PAIRED_SUCCESS];
        }break;
        case OPERATING_UPLOADED_RESULTS_PROCESS:
        {
            [self.bleConnector disConnectPeripheral];
            [self releaseResources];
            [self handleDataUploadResults:DATA_UPLOAD_SUCCESS];
            
        }break;
        default:
        {
            [self cancelDeviceConnected];
        }break;
    }
}



#pragma mark - LSBleConnector Delegate

/*
 *  连接设备成功
 */
-(void)bleConnectorDidConnectedPeripheralGatt
{
    [self debugMessage:@"successfully connect peripheral...." debuglevel:DEBUG_LEVEL_GENERAL];
    [self updateDeviceConnectStatus:CONNECTED_SUCCESS];
}

/*
 *  连接设备失败
 */
-(void)bleconnectorDidFailtoConnectPeripheralGatt
{
    //debug message
    [self debugMessage:@"failed to connect peripheral......" debuglevel:DEBUG_LEVEL_GENERAL];
    
    [self updateDeviceConnectStatus:CONNECTED_FAILED];
    if(self.currentWorkingflow==OPERATING_CONNECT_DEVICE)
    {
        [self reconnectPeripheral:self.reconnectPeripheral];
    }
    else
    {
        [self cancelDeviceConnected];
    }
}

/*
 *  设备断开连接
 */
-(void)bleConnectorDidDisConnectedPeripheralGatt
{
    [self updateDeviceConnectStatus:DISCONNECTED];
    
    if(self.currentWorkingflow==OPERATING_CONNECT_DEVICE)
    {
        [self reconnectPeripheral:self.reconnectPeripheral];
        return ;
    }
    else if (self.currentWorkingStatus==ProcessorWorkingStatusPairing
             && self.currentWorkingflow==OPERATING_READ_DEVICE_INFO)
    {
        [self reconnectPeripheral:self.reconnectPeripheral];
        return ;
    }
    else if(self.currentWorkingflow==OPERATING_PAIRED_RESULTS_PROCESS
            ||self.currentWorkingflow==OPERATING_UPLOADED_RESULTS_PROCESS)
    {
        [self handleProtocolWorkingflow:self.currentWorkingflow];
        return ;
    }
    else
    {
        NSString *msg=[NSString stringWithFormat:@"Error !Abnormal disconnect...%@",[LSProtocolWorkflow enumToString:self.currentWorkingflow]];
        [self debugMessage:msg debuglevel:DEBUG_LEVEL_GENERAL];
        
        [self cancelDeviceConnected];
        
    }
    
}

/*
 *  发现设备服务号失败，回调接口
 */
-(void)bleConnectorDidFailtoDiscoveredServices
{
    [self debugMessage:@"failed to discover services...." debuglevel:DEBUG_LEVEL_GENERAL];
    if(self.currentWorkingflow==OPERATING_CONNECT_DEVICE)
    {
        [self reconnectPeripheral:self.reconnectPeripheral];
    }
    else
    {
        [self cancelDeviceConnected];
    }
}

/*
 *  发现服务号
 */
-(void)bleConnectorDidDiscoveredGattServices:(NSArray *)gattServices
{
    self.currentDiscoveredLsService=[self parsingDiscoveredLsService:gattServices];
    if(self.currentDiscoveredLsService==0)
    {
        [self cancelDeviceConnected];
        return ;
    }
    else
    {
        self.lsDeviceGattServices=gattServices;
        ProtocolWorkflow nextWorkflow=[self getNextWorkingflow];
        if (nextWorkflow==OPERATING_READ_DEVICE_INFO)
        {
            [self discoverCharacteristicForServiceType:DEVICEINFO_SERVICE_UUID];
        }
        else if (nextWorkflow==OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS)
        {
            [self discoverCharacteristicForServiceType:self.currentDiscoveredLsService];
        }
    }
}
/*
 *  发现特征号
 */
-(void)bleConnectorDidDiscoveredCharacteristicForService:(CBService *)service
{
    uint16_t serviceValue=[LSFormatConverter uintValueWithCBUUID:service.UUID];
    if(serviceValue==DEVICEINFO_SERVICE_UUID)
    {
        for(CBCharacteristic *infoCharacteristic in service.characteristics)
        {
            uint16_t value=[LSFormatConverter uintValueWithCBUUID:infoCharacteristic.UUID];
            if([LSDeviceProfiles checkingDeviceInfoCharacteristic:value])
            {
                
                [self.deviceInfoCharacteristicQueue enqueue:infoCharacteristic];
            }
        }
    }
    if (serviceValue==self.currentDiscoveredLsService)
    {
        for (CBCharacteristic *notifyCharacteristic in service.characteristics)
        {
            if (notifyCharacteristic.properties==CBCharacteristicPropertyIndicate
                ||notifyCharacteristic.properties==CBCharacteristicPropertyNotify)
            {
                [self.notifyCharacteristicQueue enqueue:notifyCharacteristic];
            }
        }
    }
    
    self.lsDeviceCharacteristics=service.characteristics;
    [self handleProtocolWorkingflow:self.currentWorkingflow];
}

-(void)bleConnectorDidUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
{
    self.currentNotifyCharacteristic=[self getNextNotifyCharacteristic];
    if(self.currentNotifyCharacteristic)
    {
        [self handleSetNotifyWithCharacteristic:self.currentNotifyCharacteristic];
    }
    else if(self.doneOfSetNotify)
    {
        NSString *protocolType=self.currentConnectedDevice.protocolType;
        if([PROTOCOL_TYPE_KITCHEN isEqualToString:protocolType]
           ||[PROTOCOL_TYPE_GENERIC_FAT isEqualToString:protocolType])
        {
            self.currentWorkingflow=[self getNextWorkingflow];
        }
        else if([PROTOCOL_TYPE_BLOOD_PRESSURE_COMMAND_START isEqualToString:protocolType])
        {
            self.currentWorkingflow=[self getNextWorkingflow];
            if(self.currentWorkingflow==OPERATING_WRITE_START_MEASURE_COMMAND_TO_DEVICE)
            {
                [self debugMessage:@"waiting for write command to start measuring..." debuglevel:DEBUG_LEVEL_SUPREME];
                
                if([self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidWaitingForCommandToStartMeasuring:)])
                {
                    [self.bleProtocolDelegate bleProtocolDidWaitingForCommandToStartMeasuring:self.currentConnectedDevice.deviceId];
                }
            }
            else [self cancelDeviceConnected];
        }
    }
}
/*
 *  特征改变回调接口
 */
-(void)bleConnectorDidUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
{
    if(characteristic)
    {
        uint16_t serviceValue=[LSFormatConverter uintValueWithCBUUID:characteristic.service.UUID];
        if(serviceValue==DEVICEINFO_SERVICE_UUID)
        {
            //保存设备信息
            [self handleSaveDeviceInfoFromCharacteristic:characteristic];
            self.currentInfoCharacteristic=[self getNextDeviceInfoCharacteristic];
            
            //判断设备信息是否读取完成，是则打开其他特征通道
            if(self.currentInfoCharacteristic)
            {
                [self handleReadDeviceInfoWithCharacteristic:self.currentInfoCharacteristic];
            }
            else if (self.doneOfReadDeviceInfo)
            {
                self.doneOfReadDeviceInfo=NO;
                //返回设备信息
                if([self.bleProtocolDelegate respondsToSelector:@selector(bleProtocolDidDiscoverdDeviceInfo:)])
                {
                    [self.bleProtocolDelegate bleProtocolDidDiscoverdDeviceInfo:self.currentConnectedDevice];
                }
                self.currentWorkingflow=[self getNextWorkingflow];
                [self discoverCharacteristicForServiceType:self.currentDiscoveredLsService];
            }
        }
        else
        {
            //处理特征改变时，发送上来的命令
            [self handleUploadMessageForCharacteristic:characteristic];
        }
    }
    else
    {
        [self debugMessage:@"failed to get update value from characteristic" debuglevel:DEBUG_LEVEL_GENERAL];
    }
}

/*
 *  写完命令后的回调接口
 */
-(void)bleConnectorDidWrittenValueForCharacteristic:(CBCharacteristic *)characteristic
{
    NSString *writeMsg=[NSString stringWithFormat:@"write success with status - %@",[LSProtocolWorkflow enumToString:self.currentWorkingflow]];
    
    [self debugMessage:writeMsg debuglevel:DEBUG_LEVEL_SUPREME];
    
    [self handleCallbackEventsForCommandWriteSuccess];
}



@end
