//
//  LSPedometerUserInfo.m
//  LifesenseBle
//
//  Created by lifesense on 14-8-1.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import "LSPedometerUserInfo.h"

@implementation LSPedometerUserInfo


-(NSData*)unitConversionCommandData
{
    uint8_t value[3]={0};
    value[0] = 0x05;
    value[1] = 0x00;
    value[2] = 0x00;
    
    if(self.hourSystem==HOUR_12)
    {
        value[2]=(value[2] | 0x08);
    }
    if(self.lengthUnit == LENGTH_UNIT_MILE)
    {
        value[2] = (value[2] | 0x04);
    }
    
    return [NSData dataWithBytes:value length:3];
}

-(NSData *)currentStateCommandData
{
    uint8_t value[20]={0};
    value[0] = 0x05;
    uint8_t flag = 0;
    int byteCount = 2;
    //set the hourSystem and lengthUnit
    value[2] = 0x00;
    
    if(self.hourSystem==HOUR_12)
    {
        value[2]=(value[2] | 0x08);
    }
    if(self.lengthUnit == LENGTH_UNIT_MILE)
    {
        value[2] = (value[2] | 0x04);
    }
    
    byteCount++;
    flag = 0x01;
    value[byteCount] = _userNo;
    byteCount++;
    if (_weight>0) {
        
        flag = flag|0x02;
        uint32_t weightFLOAT = [self generateFLOATWithValue:_weight];
        value[byteCount] = weightFLOAT&0xff;
        byteCount++;
        weightFLOAT = weightFLOAT>>8;
        value[byteCount]= weightFLOAT&0xff;
        byteCount++;
        weightFLOAT = weightFLOAT>>8;
        value[byteCount]= weightFLOAT&0xff;
        byteCount++;
        weightFLOAT = weightFLOAT>>8;
        value[byteCount]=weightFLOAT&0xff;
        byteCount++;
        
    }
    /*
     if (_fatRatio>0) {
     
     flag = flag|0x04;
     uint16_t fatRatioSFLOAT = [self generateSFLOATWithVaule:_fatRatio];
     value[byteCount] = fatRatioSFLOAT&0xff;
     byteCount++;
     fatRatioSFLOAT=fatRatioSFLOAT>>8;
     value[byteCount] = fatRatioSFLOAT&0xff;
     byteCount++;
     
     }
     */
    if (_height>0) {
        
        flag = flag|0x08;
        uint16_t heightSFLOAT = [self generateSFLOATWithVaule:_height];
        value[byteCount] = heightSFLOAT&0xff;
        byteCount++;
        heightSFLOAT = heightSFLOAT>>8;
        value[byteCount] = heightSFLOAT&0xff;
        byteCount++;
        
    }
    /*
     if (_waistline>0) {
     
     flag = flag|0x10;
     uint16_t waistlineSFLOAT = [self generateSFLOATWithVaule:_waistline];
     value[byteCount] = waistlineSFLOAT&0xff;
     byteCount++;
     waistlineSFLOAT = waistlineSFLOAT>>8;
     value[byteCount] = waistlineSFLOAT&0xff;
     byteCount++;
     }
     */
    /*
     if (_stride>0) {
     
     flag = flag|0x20;
     uint16_t strideSFLOAT = [self generateSFLOATWithVaule:_stride];
     value[byteCount] = strideSFLOAT&0xff;
     byteCount++;
     strideSFLOAT = strideSFLOAT>>8;
     value[byteCount] = strideSFLOAT&0xff;
     byteCount++;
     }
     */
    if (_age>=0) {
        
        flag = flag|0x40;
        value[byteCount] = _age;
        byteCount++;
    }
    value[1] = flag;
    
    return [NSData dataWithBytes:value length:byteCount];


}

#pragma mark set uesr message command 0x04 to pedometer

-(NSData*)userMessageCommandData
{
    uint8_t value[11]={0};
    value[0] = 0x04;
    uint8_t flag = 0;
    int byteCount = 2;
    
    /*
    uint32_t userId = _userId;
    value[byteCount] = userId&0xff;
    byteCount++;
    userId = userId>>8;
    value[byteCount] = userId&0xff;
    byteCount++;
    userId = userId>>8;
    value[byteCount] = userId&0xff;
    byteCount++;
    userId = userId>>8;
    value[byteCount] = userId&0xff;
    */
    uint32_t userId = 100;
    value[byteCount] = userId&0xff;
    
    byteCount++;
    flag = 0x01;
    value[byteCount] = _userNo;
    byteCount++;
    if (_userGender==SEX_MALE||_userGender==SEX_FEMALE)
    {
        
        flag = flag|0x02;
        value[byteCount] = _userGender;
        byteCount++;
    }
    if (_athleteActivityLevel>=1 && _athleteActivityLevel<=5) {
        
        flag = flag|0x04;
        value[byteCount] = _athleteActivityLevel;
        byteCount++;
    }
    /*
    if (_birthdayYear>=0&&_birthdayYear<=0x0fff&&_birthdayMonth>=1&&_birthdayMonth<=12&&_birthdayDay>=1&&_birthdayDay<=31) {
        
        flag = flag|0x08;
        uint16_t year = userMessageInfo.birthdayYear;
        value[byteCount] = ((year&0x0f)<<4)|(_birthdayMonth&0x0f);
        year = year>>4;
        byteCount++;
        value[byteCount] = year&0x0fff;
        byteCount++;
        value[byteCount] = _birthdayDay;
        byteCount++;
    }
     */
    if (_weekStart==1||_weekStart==2) {
        
        flag = flag|0x10;
        value[byteCount] = _weekStart;
        byteCount++;
    }
    value[1] = flag;
    
    NSData *valueData = [NSData dataWithBytes:value length:byteCount];
    return valueData;

}

-(NSData*)weekTargetCommandData
{
    uint8_t value[19]={0};
    value[0] = 0x08;
    uint8_t flag = 0;
    int byteCount = 2;
    flag = 0x01;
    value[byteCount] = _userNo;
    byteCount++;
    if (_targetStep>0)
    {
        
        flag = flag|0x02;
        uint32_t targetStepFLOAT = [self generateFLOATWithValue:_targetStep];
        value[byteCount] = targetStepFLOAT&0xff;
        byteCount++;
        targetStepFLOAT = targetStepFLOAT>>8;
        value[byteCount] = targetStepFLOAT&0xff;
        byteCount++;
        targetStepFLOAT = targetStepFLOAT>>8;
        value[byteCount] = targetStepFLOAT&0xff;
        byteCount++;
        targetStepFLOAT = targetStepFLOAT>>8;
        value[byteCount] = targetStepFLOAT&0xff;
        byteCount++;
        
    }
    /*
    if (exerciseTargetInfo.targetCalories>0)
    {
        
        flag = flag|0x04;
        uint32_t targetCaloriesFLOAT = [self generateFLOATWithValue:exerciseTargetInfo.targetCalories];
        value[byteCount] = targetCaloriesFLOAT&0xff;
        byteCount++;
        targetCaloriesFLOAT = targetCaloriesFLOAT>>8;
        value[byteCount] = targetCaloriesFLOAT&0xff;
        byteCount++;
        targetCaloriesFLOAT = targetCaloriesFLOAT>>8;
        value[byteCount] = targetCaloriesFLOAT&0xff;
        byteCount++;
        targetCaloriesFLOAT = targetCaloriesFLOAT>>8;
        value[byteCount] = targetCaloriesFLOAT&0xff;
        byteCount++;
       
    }
    if (exerciseTargetInfo.targetDistance)
    {
        
        flag = flag|0x08;
        uint32_t targetDistanceFLOAT = [self generateFLOATWithValue:exerciseTargetInfo.targetDistance];
        value[byteCount] = targetDistanceFLOAT&0xff;
        byteCount++;
        targetDistanceFLOAT = targetDistanceFLOAT>>8;
        value[byteCount] = targetDistanceFLOAT&0xff;
        byteCount++;
        targetDistanceFLOAT = targetDistanceFLOAT>>8;
        value[byteCount] = targetDistanceFLOAT&0xff;
        byteCount++;
        targetDistanceFLOAT = targetDistanceFLOAT>>8;
        value[byteCount] = targetDistanceFLOAT&0xff;
        byteCount++;
      
    }
    if (exerciseTargetInfo.targetExerciseAmount>0)
    {
        
        flag = flag|0x10;
        uint32_t tempAmount = exerciseTargetInfo.targetExerciseAmount*10*10;
        Byte *byteAmount = (Byte*)(&tempAmount);
        value[byteCount++] = *byteAmount;
        value[byteCount++] = *(byteAmount +1);
        value[byteCount++] = *(byteAmount +2);
        value[byteCount++] = 0xfe;
    }
     */
    value[1] = flag;
    
    NSData *valueData = [NSData dataWithBytes:value length:byteCount];
   
    return valueData;
}

-(BOOL)isUserMessageSetting
{
    if(_weekStart==1||_weekStart==2)
    {
        return YES;
    }
    else return NO;
}

-(BOOL)isWeekStartSetting
{
    if(_targetStep>0)
    {
        return YES;
    }
    else return NO;
}

-(BOOL)isCurrentStateSetting
{
    if(_weight>0 && _height>0 && _age>0)
    {
        return YES;
    }
    else return NO;
}

-(BOOL)isUnitConversionSetting
{
    if(_hourSystem==HOUR_12||_hourSystem==HOUR_24)
    {
        return YES;
    }
    else if (_lengthUnit==LENGTH_UNIT_KILOMETER||_lengthUnit==LENGTH_UNIT_MILE)
    {
        return YES;
    }
    else return NO;
}

//old 
-(NSData*)currentStateBytes
{
    uint8_t value[3]={0};
    value[0] = 0x05;
    value[1] = 0x00;
    value[2] = 0x00;
    
    if(self.hourSystem==HOUR_12)
    {
        value[2]=(value[2] | 0x08);
    }
    if(self.lengthUnit == LENGTH_UNIT_MILE)
    {
        value[2] = (value[2] | 0x04);
    }
    
    return [NSData dataWithBytes:value length:3];

}

#pragma mark private methods

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

-(uint16_t)generateSFLOATWithVaule:(double)value
{
    uint16_t result = 0;
    int8_t exponent = 0;
    NSNumber *valueNumber = [NSNumber numberWithFloat:value];
    NSDecimal valueDecimal = [valueNumber decimalValue];
    exponent = valueDecimal._exponent;
    uint32_t mantissa = 0;
    if (valueDecimal._length==2)
    {
        
        mantissa = valueDecimal._mantissa[1];
        mantissa = mantissa<<16;
        mantissa = mantissa|valueDecimal._mantissa[0];
        
    }else
    {
        mantissa = valueDecimal._mantissa[0];
    }
    if (!valueDecimal._isNegative) {
        
        while (mantissa>=0x07fe) {
            
            double mediate = mantissa/10.0;
            mantissa = round(mediate);
            exponent = exponent+1;
        }
        if (exponent<-8) {
            
            result = 0;
        }else if(exponent<0)
        {
            exponent = exponent+16;
            result = result|exponent;
            result = result<<12;
            result = result|mantissa;
        }else if (exponent<8)
        {
            result = result|exponent;
            result = result<<12;
            result = result|mantissa;
        }else
        {
            result = 0x07fe; //it is for +INFINITY
        }
    }
    
    return result;
}



@end
