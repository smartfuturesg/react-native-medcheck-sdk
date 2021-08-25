//
//  LSProductUserInfo.m
//  LsBluetooth-Test
//
//  Created by lifesense on 14-8-12.
//  Copyright (c) 2014年 com.lifesense.ble. All rights reserved.
//

#import "LSProductUserInfo.h"

@implementation LSProductUserInfo

-(NSData *)userInfoCommandData
{
    uint8_t value[15] = {0};
    value[0] = 0x51;
    int count = 1;
    
    //有用户信息要写
    value[count++] = 223;   //标记位
    value[count++] = self.userNumber;     //userNumber

    NSUInteger defaultSexValue=1;
    if(self.sex==SEX_FEMALE)
    {
        if(self.athleteLevel>0)
        {
            defaultSexValue=4;
        }
        else defaultSexValue=2;
    }
    else if(self.sex==SEX_MALE)
    {
        if(self.athleteLevel>0)
        {
            defaultSexValue=3;
        }
        else defaultSexValue=1;
    }
    
    value[count++] = defaultSexValue;     //user sex
    value[count++] = self.age;    //user age
    uint16_t tempHeight = self.height*10*10;
    Byte *byteHeight = (Byte *)(&tempHeight);
    value[count++] = *(byteHeight);
    uint8_t temp1 = 0xe;
    temp1 = temp1<<4;
    uint8_t temp2 = *(byteHeight +1);
    temp2 = temp2&0x0f;
    value[count++] = temp1|temp2;
    
    value[count++] = self.athleteLevel;     //运动员级别
    
    //测量单位

    if (self.unit==UNIT_LB) {
        value[count++] = 1;
    }
    else if (self.unit==UNIT_ST) {
        value[count++] = 2;
    }
    else
    {
        value[count++] = 0;
    }
    
    if(self.goalWeight>0)
    {
        uint32_t weightFLOAT = [self generateFLOATWithValue:self.goalWeight];
        value[count++]=weightFLOAT&0xff;
        weightFLOAT = weightFLOAT>>8;
        value[count++]=weightFLOAT&0xff;
        weightFLOAT = weightFLOAT>>8;
        value[count++]=weightFLOAT&0xff;
        weightFLOAT = weightFLOAT>>8;
        value[count++]=weightFLOAT&0xff;
    }
    else
    {
        value[count++]=0;
        value[count++]=0;
        value[count++]=0;
        value[count++]=0;
    }
    
    
    NSData*valueData =[NSData dataWithBytes:value length:count];
    return valueData;
    
    
}

#pragma mark -private methods 

-(uint32_t)generateFLOATWithValue:(double)value
{
    uint32_t result = 0;
    int8_t exponent = 0;
    
    NSNumber *valueNumber = [NSNumber numberWithFloat:value];
    NSDecimal valueDecimal = [valueNumber decimalValue];
    exponent = valueDecimal._exponent;
    uint32_t mantissa = 0;
    if (valueDecimal._length==2) {
        
        mantissa = valueDecimal._mantissa[1];
        mantissa = mantissa<<16;
        mantissa = mantissa|valueDecimal._mantissa[0];
        
    }else
    {
        mantissa = valueDecimal._mantissa[0];
    }
    if (!valueDecimal._isNegative) {
        
        while (mantissa>=0x007ffffe) {
            
            double mediate = mantissa/10.0;
            mantissa = round(mediate);
            exponent = exponent+1;
        }
        result = result|exponent;
        result = result<<24;
        result = result|mantissa;
        
    }
    
    return result;
}

@end
