//
//  LSVibrationVoice.m
//  LSBluetooth-Library
//
//  Created by lifesense on 14-11-17.
//  Copyright (c) 2014年 Lifesense. All rights reserved.
//

#import "LSVibrationVoice.h"
#import "LSBleGattServicesConstants.h"

@implementation LSVibrationVoice


//获取振动声音对象的bytes,用于写到设备
-(NSData*)getCommandDataBytes
{
   
    
    uint8_t value[12]={0};
    value[0]=VIBRATION_VOICE_COMMAND;
    int i=3;
    if(self.isEnableVibration)
    {
        value[1]=value[1]+1;
        value[i]=self.vibrationIntensity;
        i++;
        value[i]=self.vibrationTimes;
        i++;
        value[i]=self.continuousVibrationTime;
        i++;
        value[i]=self.pauseVibrationTime;
        i++;
    }
    if(self.isEnableSound)
    {
        value[1]=value[1]+2;
        value[i]=self.soundSelect;
        i++;
        value[i]=self.soundTimes;
        i++;
        value[i]=self.volumeSetting;
        i++;
        value[i]=self.continuousSoundTime;
        i++;
        value[i]=self.pauseSoundTime;
    }
    value[2]=self.productUserNumber;
    
    
    NSData*data=[NSData dataWithBytes:value length:12];
    return data;
}
@end
