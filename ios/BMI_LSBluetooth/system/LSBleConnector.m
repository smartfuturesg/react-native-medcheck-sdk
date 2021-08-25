//
//  LSBLEConnector.m
//  LifesenseBle
//
//  Created by lifesense on 14-8-1.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import "LSBleConnector.h"
#import "LSBleGattServicesConstants.h"
#import "BleDebugLogger.h"
#import <CoreBluetooth/CBPeripheralManager.h>
#import <CoreBluetooth/CBCentralManager.h>
#import <CoreBluetooth/CBService.h>
#import <CoreBluetooth/CBCharacteristic.h>
#import <CoreBluetooth/CBDescriptor.h>
#import "DispatchBasedTimer.h"

@interface LSBleConnector()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property(nonatomic,strong) CBCentralManager *centralManager;
@property(nonatomic,readwrite)BOOL isScanning;
@property(nonatomic,strong)NSArray *lsDeviceServices;
//@property(nonatomic,strong)NSTimer *connectTimer;
@property(nonatomic,strong)DispatchBasedTimer *connectTimer;
@property(nonatomic,strong)CBPeripheral *connectedPeripheral;

//new change for version 3.0.4
@property(nonatomic,strong)NSMutableArray* subscribedCharacteristics;


@property(nonatomic,strong)id<LSBleStatusChangeDelegate>bleStatusDelegate ;
@end
@implementation LSBleConnector

-(instancetype)init
{
    self=[super init];
    if(self)
    {
        self.isScanning=NO;
        self.connectedPeripheral=nil;
         [self setDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    return self;
}


#pragma mark - public api

-(void)setDispatchQueue:(dispatch_queue_t)dispatchQueue
{
    _dispatchQueue = dispatchQueue;
    _centralManager=[[CBCentralManager alloc] initWithDelegate:self queue:dispatchQueue options:nil];
}

/*
 * 检测终端设备当前的蓝牙状态
 */
-(void)checkBluetoothStatus:(id<LSBleStatusChangeDelegate>)bleStateDelegate
{
    if(!bleStateDelegate)
    {
        [BleDebugLogger object:self printMessage:@"completion handler block is nil" withDebugLevel:DEBUG_LEVEL_GENERAL];
        return;
    }
    self.bleStatusDelegate=bleStateDelegate;
    
}

/*
 * 启动扫描，搜索指定服务号的乐心设备，
 */
-(BOOL)scanWithServices:(NSArray *)services
{
    if(services)
    {
        //debug message
        NSString *msg=[NSString stringWithFormat:@"start scan with services:%@",services];
        [BleDebugLogger object:self printMessage:msg withDebugLevel:DEBUG_LEVEL_SUPREME];
        
        self.lsDeviceServices=services;
        NSDictionary *option = [NSDictionary
                                dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], CBCentralManagerScanOptionAllowDuplicatesKey,nil];
        [self.centralManager scanForPeripheralsWithServices:services options:option];
        return self.isScanning=YES;
    }
    else
    {
        [BleDebugLogger object:self printMessage:@"Error!can't start scan ,because of no services " withDebugLevel:DEBUG_LEVEL_GENERAL];
        return self.isScanning=NO;
    }
}

/*
 * 停止扫描
 */
-(void)stopScan
{
    if(self.isScanning)
    {
        [BleDebugLogger object:self printMessage:@"stop scan" withDebugLevel:DEBUG_LEVEL_GENERAL];
        self.isScanning=NO;
        [self.centralManager stopScan];
    }
}

/*
 *  连接外围设备
 */
-(void)connectPeripheral:(CBPeripheral *)lsPeripheral
{
    if(lsPeripheral)
    {
        self.connectedPeripheral=nil;
        NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],CBConnectPeripheralOptionNotifyOnDisconnectionKey, nil];
        //连接定时器，若10秒内连接失败，则进行自动连接
        if (lsPeripheral.state!=CBPeripheralStateConnected)
        {
            [self.centralManager connectPeripheral:lsPeripheral options:nil];
            
            self.connectTimer = [DispatchBasedTimer timerWithDispatchQueue:self.dispatchQueue
                                                     timeoutInMilliSeconds:10000
                                                                  andBlock:^{
                                                                      [self connectTimerOut:lsPeripheral];
                                                                  }];
        }
       /*
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                self.connectTimer = [NSTimer timerWithTimeInterval:10
                                                            target:self
                                                          selector:@selector(connectTimerOut:)
                                                          userInfo:lsPeripheral
                                                           repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSDefaultRunLoopMode];
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
            });
            
        }
        */
    }
    else
    {
        //debug messgae
        [BleDebugLogger object:self printMessage:@"Failed to connect peripheral,because of peripheral is nil" withDebugLevel:DEBUG_LEVEL_GENERAL];
    }
    
}

/*
 *  断开与外围设备建立的连接
 */
-(void)disConnectPeripheral
{
    if(self.connectedPeripheral)
    {
        //debug message
        [BleDebugLogger object:self printMessage:@"disconnect peripheral" withDebugLevel:DEBUG_LEVEL_GENERAL];
      for (CBCharacteristic *characteristic in self.subscribedCharacteristics)
      {
              [self setNotifyValue:NO forCharacteristic:characteristic];
      }
        
       [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
        self.connectedPeripheral=nil;
    }
}


/*
 *  根据服务号，主动发现服务号所包含的特征号
 */
-(void)discoverCharacteristicsForService:(CBService *)service
{
    if([self checkPeripheralConnectState])
    {
        if(service.UUID)
        {
            [self.connectedPeripheral setDelegate:self];
            [self.connectedPeripheral discoverCharacteristics:nil forService:service];
        }
        else
        {
            NSString *errorMsg=[NSString stringWithFormat:@"Error! failed to discovered characteristic,for service(%@)",service.UUID];
            [BleDebugLogger object:self printMessage:errorMsg
                 withDebugLevel:DEBUG_LEVEL_GENERAL];
        }
    }
}

/*
 *  读取指定特征号的数据
 */
-(void)readValueForCharacteristic:(CBCharacteristic *)characteristic
{
    if([self checkPeripheralConnectState])
    {
        if(characteristic)
        {
            
            [self.connectedPeripheral setDelegate:self];
            [self.connectedPeripheral readValueForCharacteristic:characteristic];
        }
        else
        {
            NSString *errorMsg=[NSString stringWithFormat:@"Error!failed to read characteristic value ,for characteristic (%@)",characteristic];
            [BleDebugLogger object:self printMessage:errorMsg withDebugLevel:DEBUG_LEVEL_GENERAL];
        }
    }
}

/*
 *  设置指定特征号的notify值
 */
-(void)setNotifyValue:(BOOL)notifyFlags forCharacteristic:(CBCharacteristic *)lsCharacteristic
{
    if([self checkPeripheralConnectState])
    {
        
        if (notifyFlags)
          {
               [self.subscribedCharacteristics addObject:lsCharacteristic];
        }
        
        if(lsCharacteristic)
        {
            [self.connectedPeripheral setDelegate:self];
            [self.connectedPeripheral setNotifyValue:notifyFlags
                                   forCharacteristic:lsCharacteristic];
        }
        else
        {
            NSString *errorMsg=[NSString stringWithFormat:@"Error ! failed to set notify,for characteristic(%@)",lsCharacteristic];
            [BleDebugLogger object:self printMessage:errorMsg
                 withDebugLevel:DEBUG_LEVEL_GENERAL];
        }
        
    }
    
}

/*
 *  向指定特征号写入数据、命令
 */
-(void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)downloadCharacteristic
{
    if([self checkPeripheralConnectState])
    {
        if(data && downloadCharacteristic)
        {
            [self.connectedPeripheral setDelegate:self];
            [self.connectedPeripheral writeValue:data
                               forCharacteristic:downloadCharacteristic
                                            type:CBCharacteristicWriteWithResponse];
        }
        else
        {
            NSString *errorMsg=[NSString stringWithFormat:@"Error ! failed to write value(%@),for characteristic(%@)",data,downloadCharacteristic];
            [BleDebugLogger object:self printMessage:errorMsg
                 withDebugLevel:DEBUG_LEVEL_GENERAL];
        }
        
    }
    
}

- (void)setConnectedPeripheral:(CBPeripheral *)connectedPeripheral
{
     _connectedPeripheral = connectedPeripheral;
     self.subscribedCharacteristics = [NSMutableArray array];
}

#pragma mark - private methods

-(NSString *)dataToString:(NSData *)data
{
    if(data)
    {
        NSString *tempString=data.description;
        tempString = [tempString stringByReplacingOccurrencesOfString:@"<" withString:@""];
        tempString = [tempString stringByReplacingOccurrencesOfString:@">" withString:@""];
        tempString = [tempString stringByReplacingOccurrencesOfString:@" " withString:@""];
        return tempString;
    }
    else return nil;
}
/*
 *连接超时，定时器
 */
-(void)connectTimerOut:(CBPeripheral *)peripheral
{
    [BleDebugLogger object:self printMessage:@"connect time out，try to connect peripheral again" withDebugLevel:DEBUG_LEVEL_GENERAL];
    if (peripheral)
    {
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

/*
 *  检查当前外围设备的连接状态
 */
-(BOOL)checkPeripheralConnectState
{
    if(self.connectedPeripheral && self.connectedPeripheral.state!=CBPeripheralStateDisconnected)
    {
        return YES;
    }
    else
    {
        //debug message
        NSString *errorMsg=[NSString stringWithFormat:@"Error! disconnect ,peripheral(%@) connect state is(%ld)",self.connectedPeripheral,self.connectedPeripheral.state];
        [BleDebugLogger object:self printMessage:errorMsg withDebugLevel:DEBUG_LEVEL_GENERAL];
        return NO;
    }
}
#pragma mark - CBCentralManager Delegate

/*
 *处理手机蓝牙状态
 */
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if([self.bleStatusDelegate respondsToSelector:@selector(bleConnectorDidBluetoothStatusChange:)])
    {
        [self.bleStatusDelegate bleConnectorDidBluetoothStatusChange:central.state];
    }
    
    NSString *stateMsg = nil;
    if(central.state==CBCentralManagerStateUnsupported)
    {
        stateMsg = @"The platform not support the Bluetooth Low energy.";
    }
    else if(central.state==CBCentralManagerStateUnauthorized)
    {
        stateMsg = @"The app is not authorized to use the Bluetooth Low energy.";
    }
    else if(central.state==CBCentralManagerStatePoweredOff)
    {
        stateMsg = @"Bluetooth is poweredoff now.";
    }
    else if(central.state==CBCentralManagerStatePoweredOn)
    {
        stateMsg = @"Bluetooth is ready for use.";
    }
    else if(central.state==CBCentralManagerStateUnknown)
    {
        stateMsg = @"The state of Bluetooth is unknow";
        
    }
    [BleDebugLogger object:self printMessage:stateMsg withDebugLevel:DEBUG_LEVEL_GENERAL];
    
}

/*
 *发现外围设备的回调接口，即扫描结果
 */
-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary *)advertisementData
                 RSSI:(NSNumber *)RSSI
{
    NSLog(@"advertisementData: %@",advertisementData);
    //debug message
    NSString *detailsMsg=[NSString stringWithFormat:@"discover peripheral:%@ perpheral.name:%@ ,advertisementData:%@",peripheral,peripheral.name,advertisementData];
    [BleDebugLogger object:self printMessage:detailsMsg withDebugLevel:DEBUG_LEVEL_SUPREME];
    
    NSData *manufacturerData=[advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
    
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    NSArray *serviceUUIDs = [advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey];
    
  
    
    if (localName.length==0||([serviceUUIDs count]==0))
    {
        return;
    }
    else
    {
        if([self.bleConnectorDelegate respondsToSelector:@selector(bleConnectorDidScanResults:broadcastName:serviceLists:manufacturerData:)])
        {
            [self.bleConnectorDelegate bleConnectorDidScanResults:peripheral
                                                    broadcastName:localName
                                                     serviceLists:serviceUUIDs
                                                 manufacturerData:[self dataToString:manufacturerData]];
        }
    }
    
}

/*
 *连接设备的回调结果
 */
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //取消连接超时定时器
    if (self.connectTimer)
    {
        [self.connectTimer cancel];
        self.connectTimer = nil;
    }
    self.connectedPeripheral=[peripheral copy];
    [self.connectedPeripheral setDelegate:self];
    //开始发现服务号
    [self.connectedPeripheral discoverServices:nil];
    
    //返回连接结果
    if ([self.bleConnectorDelegate respondsToSelector:@selector(bleConnectorDidConnectedPeripheralGatt)])
    {
        [self.bleConnectorDelegate bleConnectorDidConnectedPeripheralGatt];
    }
    
}


/*
 *设备断开连接的回调结果
 */
-(void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                error:(NSError *)error
{
    //设备断开连接
    [BleDebugLogger object:self printMessage:@"Device is disconnected" withDebugLevel:DEBUG_LEVEL_GENERAL];
    
    self.connectedPeripheral.delegate=nil;
    self.connectedPeripheral=nil;
    
    if ([self.bleConnectorDelegate respondsToSelector:@selector(bleConnectorDidDisConnectedPeripheralGatt)])
    {
        [self.bleConnectorDelegate bleConnectorDidDisConnectedPeripheralGatt];
    }
}

/*
 *连接设备失败的回调结果
 */
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [BleDebugLogger object:self printMessage:@"Failed to connected peripheral" withDebugLevel:DEBUG_LEVEL_GENERAL];
    
    if (self.connectTimer)
    {
        [self.connectTimer cancel];
        self.connectTimer = nil;
    }
    if ([self.bleConnectorDelegate respondsToSelector:@selector(bleconnectorDidFailtoConnectPeripheralGatt)])
    {
        [self.bleConnectorDelegate bleconnectorDidFailtoConnectPeripheralGatt];
    }
}

#pragma mark - CBPeripheral Delegate

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [BleDebugLogger object:self printMessage:@"did update notification state for characteristic...." withDebugLevel:DEBUG_LEVEL_SUPREME];
    if ([self.bleConnectorDelegate respondsToSelector:@selector(bleConnectorDidUpdateNotificationStateForCharacteristic:)])
    {
        [self.bleConnectorDelegate bleConnectorDidUpdateNotificationStateForCharacteristic:characteristic];
    }
    
    
    
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    NSLog(@"did write value for descriptor");
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"did discover descriptors for characteristic");
}
/*
 *发现设备的服务号
 */
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        [BleDebugLogger object:self printMessage:@"Failed to discover gatt services" withDebugLevel:DEBUG_LEVEL_GENERAL];
        return;
    }
    else
    {
        [BleDebugLogger object:self printMessage:@"Successfuly discover gatt services" withDebugLevel:DEBUG_LEVEL_GENERAL];
        
        self.connectedPeripheral=peripheral;
        
        if([self.bleConnectorDelegate respondsToSelector:@selector(bleConnectorDidDiscoveredGattServices:)])
        {
            [self.bleConnectorDelegate bleConnectorDidDiscoveredGattServices:peripheral.services];
        }
        
    }
    
}

/*
 *发现在某一服务号的所包括的特征号
 */
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSString *errorMsg=[NSString stringWithFormat:@"Failed to discover characteristic,current service =%@",service.UUID];
        [BleDebugLogger object:self printMessage:errorMsg withDebugLevel:DEBUG_LEVEL_GENERAL];
        return;
    }
    else
    {
        [BleDebugLogger object:self printMessage:@"Successfuly discover characteristic" withDebugLevel:DEBUG_LEVEL_GENERAL];
        self.connectedPeripheral=peripheral;
        
        if([self.bleConnectorDelegate respondsToSelector:@selector(bleConnectorDidDiscoveredCharacteristicForService:) ])
        {
            [self.bleConnectorDelegate bleConnectorDidDiscoveredCharacteristicForService:service];
        }
    }
    
}


/*
 *  处理特征通道改变时，由外围设备发送上来的数据
 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        [BleDebugLogger object:self printMessage:@"Failed to get value from characteristic" withDebugLevel:DEBUG_LEVEL_GENERAL];
        return;
    }
    else
    {
        //获取命令字节数据
        uint8_t *byte = (uint8_t*)[characteristic.value bytes];
        uint8_t command = *byte;
        
        __unused NSString *value =[[NSString alloc] initWithData:characteristic.value
                                                        encoding:NSUTF8StringEncoding];
        
        NSString *msg=[NSString stringWithFormat:@"receive push data(%@),with command(%x), from characteristic(%@)",[characteristic.value description],command,characteristic.UUID.UUIDString];
        
        [BleDebugLogger object:self printMessage:msg withDebugLevel:DEBUG_LEVEL_SUPREME];
        
        if([self.bleConnectorDelegate respondsToSelector:@selector(bleConnectorDidUpdateValueForCharacteristic:)])
        {
            [self.bleConnectorDelegate bleConnectorDidUpdateValueForCharacteristic:characteristic];
        }
    }
    
}

/*
 *  向特征号写完数据后的回调接口
 */
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSString *errorMsg=[NSString stringWithFormat:@"Error! failed to writed value to characteristic(%@)",characteristic.UUID];
        [BleDebugLogger object:self printMessage:errorMsg withDebugLevel:DEBUG_LEVEL_GENERAL];
    }
    else
    {
         NSString *msg=[NSString stringWithFormat:@"write command data(%@) to characteristic(%@)",[characteristic.value description],characteristic.UUID];
        
        [BleDebugLogger object:self printMessage:msg withDebugLevel:DEBUG_LEVEL_SUPREME];
        
        if([self.bleConnectorDelegate respondsToSelector:@selector(bleConnectorDidWrittenValueForCharacteristic:)])
        {
            [self.bleConnectorDelegate bleConnectorDidWrittenValueForCharacteristic:characteristic];
        }
    }
}

@end
