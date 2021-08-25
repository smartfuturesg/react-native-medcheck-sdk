//
//  LSBleDataParsingTools.m
//  LsBluetooth-Test
//
//  Created by lifesense on 14-8-4.
//  Copyright (c) 2014年 com.lifesense.ble. All rights reserved.
//

#import "LSBleDataParsingTools.h"
#import "BleDebugLogger.h"
#import "LSBleGattServicesConstants.h"
#import <CoreBluetooth/CBUUID.h>
#import "LSFormatConverter.h"
#import "DataUtilities.h"
#import "LSSleepRecord.h"

@implementation LSBleDataParsingTools

#pragma mark - public api

+(LSWeightData*)parseWeightAppendDataWithNormalWeight:(LSWeightData *) normalWeightDdata sourceData:(NSData*)data
{
    LSWeightAppendData *appendData = [self parseWeightAppendData:data];
    normalWeightDdata.voltageValue=appendData.voltageData;
    normalWeightDdata.batteryValue=appendData.battery;
    return normalWeightDdata;

}
/*
 *  A3 脂肪秤测量数据解析
 */
+(LSWeightAppendData*)parseWeightAppendData:(NSData*)data
{
    LSWeightAppendData *appendData = [[LSWeightAppendData alloc]init];
    
    uint8_t *byte = (uint8_t*)[data bytes];
    uint8_t flags = *byte;
    byte++;
    
    uint32_t tempUTC = byte[3];
    tempUTC = tempUTC<<8;
    tempUTC = tempUTC|byte[2];
    tempUTC = tempUTC<<8;
    tempUTC = tempUTC|byte[1];
    tempUTC = tempUTC<<8;
    tempUTC = tempUTC|(*byte);
    
    appendData.utc = tempUTC;
    appendData.measuredTime=[LSFormatConverter dateFromUTC:tempUTC];
    byte += 4;
    
    if (flags&0x01) {
        appendData.userId = *byte;
        
        byte++;
    }
    
    if ((flags>>1)&0x01) {
        uint16_t tempBasal = byte[1];
        tempBasal = (tempBasal <<8)|(*byte);
        
        appendData.basalMetabolism = [self translateToSFloat:tempBasal];
        byte += 2;
    }
    
    if ((flags>>2)&0x01) {
        uint16_t tempBodyFat = byte[1];
        tempBodyFat = (tempBodyFat<<8)|(*byte);
        
        appendData.bodyFatRatio = [self translateToSFloat:tempBodyFat];
        byte += 2;
    }
    
    if ((flags>>3)&0x01) {
        uint16_t tempBodyWater = byte[1];
        tempBodyWater = (tempBodyWater << 8)|(*byte);
        appendData.bodywaterRatio = [self translateToSFloat:tempBodyWater];
        byte += 2;
    }
    
    if ((flags>>4)&0x01) {
        uint16_t tempVisceral = byte[1];
        tempVisceral = (tempVisceral <<8)|(*byte);
        appendData.visceralFatLevel = [self translateToSFloat:tempVisceral];
        byte += 2;
    }
    
    if ((flags >>5)&0x01) {
        uint16_t tempMuscle = byte[1];
        tempMuscle = (tempMuscle <<8)|(*byte);
        
        appendData.muscleMassRatio = [self translateToSFloat:tempMuscle];
        byte += 2;
    }
    
    if ((flags>>6)&0x01) {
        uint16_t tempbone = byte[1];
        tempbone = (tempbone <<8)|(*byte);
        
        appendData.boneDensity = [self translateToSFloat:tempbone];
        byte += 2;
    }
    
    if ((flags>>7)&0x01) {
        appendData.battery=(byte[0])&0x7;
        
        if(((byte[0])&0x8)==0x8)
        {
            int tmp=byte[0];
            int hBit=((byte[0])&0x80)>>7;
            int lBit=((byte[0])&0x40)>>6;
            
            int voltage=byte[1];
            
            appendData.voltageData=(hBit*16*16*16+lBit*16*16+voltage);
            appendData.voltageData=appendData.voltageData/100.0;
        }
    }
    return appendData;
}

/*
 *  A2 体重测量数据解析
 */
+(LSWeightData*)parseWeightScaleMeasurementData:(NSData*)data
{
    uint8_t *byte = (uint8_t*)[data bytes];
    uint8_t flag = *byte;
    byte++;
    LSWeightData *measurementData = [[LSWeightData alloc]init];
    
    
    uint32_t weight = byte[3];
    
    weight = weight<<8;
    weight = weight|(byte[2]);
    
    weight = weight<<8;
    weight = weight|(byte[1]);
    
    weight = weight<<8;
    weight = weight|(byte[0]);
    byte = byte+4;
    measurementData.weight = [self translateFLOAT:weight];
    
    if (flag&0x01) {
        
        NSUInteger utc = byte[3];
        
        utc = utc<<8;
        utc = utc|(byte[2]);
        
        utc = utc<<8;
        utc = utc|(byte[1]);
        
        utc = utc<<8;
        utc = utc|(byte[0]);
        byte = byte+4;
        measurementData.date = [LSFormatConverter dateFromUTC:utc];
        measurementData.utc=(uint32_t)utc;
    }
    double lowResistance =0;
    double highResistance = 0;
    if (flag&0x02) {
        
        uint32_t impedanceValue = byte[3];
        impedanceValue = impedanceValue<<8;
        impedanceValue = impedanceValue|(byte[2]);
        impedanceValue = impedanceValue<<8;
        impedanceValue = impedanceValue|(byte[1]);
        impedanceValue = impedanceValue<<8;
        impedanceValue = impedanceValue|(byte[0]);
        lowResistance = [self translateFLOAT:impedanceValue];
        measurementData.resistance_1 = lowResistance;
        byte = byte +4;
    }
    
    if (flag&0x04) {
        uint32_t impedanceValue = byte[3];
        impedanceValue = impedanceValue<<8;
        impedanceValue = impedanceValue|(byte[2]);
        impedanceValue = impedanceValue<<8;
        impedanceValue = impedanceValue|(byte[1]);
        impedanceValue = impedanceValue<<8;
        impedanceValue = impedanceValue|(byte[0]);
        highResistance = [self translateFLOAT:impedanceValue];
        measurementData.resistance_2 = highResistance;
        byte = byte+4;
        
    }
    if (flag&0x08) {
        measurementData.userNo=*byte;
        byte++;
    }
    if (flag&0x10) {
        
        uint8_t measurementStatus = *byte;
        uint8_t weightStatus;
        uint8_t impedanceStatus;
        uint8_t hasAppendMeasurement;
        weightStatus = measurementStatus&0x01;
        measurementStatus = measurementStatus>>1;
        impedanceStatus = measurementStatus&0x07;
        measurementStatus = measurementStatus>>3;
        hasAppendMeasurement=measurementStatus&0x01;
        
        measurementData.hasAppendMeasurement=hasAppendMeasurement;
    }
    
    switch (flag&0x60) {
        case 0x00:
            measurementData.deviceSelectedUnit = [NSString stringWithFormat:@"Kg"];
            break;
            
        case 0x20:
            measurementData.deviceSelectedUnit = [NSString stringWithFormat:@"LB"];
            
            break;
            
        case 0x40:
            measurementData.deviceSelectedUnit = [NSString stringWithFormat:@"St"];
            break;
            
        case 0x60:
            measurementData.deviceSelectedUnit = [NSString stringWithFormat:@"Kg"];
            break;
            
        default:
            break;
    }
    //new change for version 2.0.0,新增根据kg转换相应的LB或ST值
    measurementData.lbWeightValue=[self calculateLbWeightValue:measurementData.weight];
    measurementData.stSectionValue=(int)(measurementData.lbWeightValue/14);
    measurementData.stWeightValue=[self calculateStWeightValue:measurementData.lbWeightValue];
    
    
    return measurementData;
}

/*
 *  A2、A3血压计测量数据解析
 */
+(LSSphygmometerData*)parseSphygmometerMeasurementData:(NSData*)data
{
    
    LSSphygmometerData *bloodPresureData = [[LSSphygmometerData alloc]init];
    uint8_t *bytes = (uint8_t *)[data bytes];
    uint8_t flag = *bytes;
    if (flag&0x01) {
        bloodPresureData.deviceSelectedUnit = [NSString stringWithFormat:@"kpa"];
    }
    else
        bloodPresureData.deviceSelectedUnit = [NSString stringWithFormat:@"mmHg"];
    
    bytes++;
    uint16_t systolic = *(bytes+1);
    systolic = systolic<<8;
    systolic = systolic |(*bytes);
    bytes = bytes+2;
    
    uint16_t diastolic = *(bytes+1);
    diastolic = diastolic<<8;
    diastolic = diastolic |(*bytes);
    bytes =bytes+2;
    bloodPresureData.systolic = [self translateSFLOAT:systolic];
    bloodPresureData.diastolic = [self translateSFLOAT:diastolic];
    
    // mean artrtial pressure
    
    uint16_t mp_perssure = *bytes;
    bytes++;
    mp_perssure = mp_perssure<<8;
    mp_perssure = mp_perssure |(*bytes);
    bytes++;
    
    //utc
    
    if (flag&0x02) {
        uint32_t utc= *(bytes +3);
        utc = utc<<8;
        utc = utc |(*(bytes +2));
        utc = utc<<8;
        utc = utc |(*(bytes+1));
        utc = utc<<8;
        utc = utc |(*bytes);
        bytes = bytes +4;
        bloodPresureData.date = [LSFormatConverter dateFromUTC:utc];
        //set utc
        bloodPresureData.utc=utc;
    }
    //pulse rate
    if (flag&0x04) {
        
        uint16_t pulse = *(bytes+1);
        pulse = pulse<<8;
        pulse = pulse |(*bytes);
        bytes =bytes+2;
        bloodPresureData.pluseRate = [self translateSFLOAT:pulse];
    }
    
    //user ID
    if (flag&0x08) {
        
        uint8_t userId = *bytes;
        bloodPresureData.userNo = userId;
        bytes++;
    }
    
    //measurement status
    if (flag&0x10) {
        bloodPresureData.isIrregularPulse = (((*bytes)&0x04)==0x04);
        bytes = bytes+2;
    }
    //battery indicate
    if (flag&0x20) {
        
        bloodPresureData.battery = *bytes;
    }
    return bloodPresureData;
}

/*
 *  计步器、运动手环测量数据解析
 */
+(LSPedometerData*)parsePedometerScaleMeasurementData:(NSData*)data
{
    LSPedometerData *pedpmeterData = [[LSPedometerData alloc]init];
    uint8_t *bytes = (uint8_t*)[data bytes];
    uint8_t flag = *bytes;
    bytes++;
    uint32_t steps = *(bytes+2);
    steps = steps<<8;
    steps = steps |*(bytes +1);
    steps = steps<<8;
    steps = steps | *bytes;
    bytes = bytes+3;
    
    if (flag&0x01) {
        pedpmeterData.runSteps = steps;
    }
    else
    {
        pedpmeterData.walkSteps = steps;
    }
    
    //utc
    uint32_t utc= *(bytes +3);
    utc = utc<<8;
    utc = utc |(*(bytes +2));
    utc = utc<<8;
    utc = utc |(*(bytes+1));
    utc = utc<<8;
    utc = utc |(*bytes);
    if (flag&0x02) {
        pedpmeterData.date = [LSFormatConverter dateFromUTC:utc];
        //set utc
        pedpmeterData.utc=utc;
    }
    //examount
    bytes = bytes +4;
    uint16_t exmount = *(bytes +1);
    exmount = exmount <<8;
    exmount = exmount |*bytes;
    pedpmeterData.examount = [self translateSFLOAT:exmount];
    
    //calories
    bytes = bytes +2;
    uint32_t calories = *(bytes+3);
    calories = calories<<8;
    calories = calories|*(bytes +2);
    calories = calories<<8;
    calories = calories|*(bytes +1);
    calories = calories<<8;
    calories = calories|*bytes;
    if (flag&0x08) {
        pedpmeterData.calories = [self translateFLOAT:calories];
    }
    
    //exercise time
    bytes = bytes +4;
    uint16_t exTime = *(bytes +1);
    exTime = exTime <<8;
    exTime = exTime | *bytes;
    if (flag&0x10) {
        pedpmeterData.exerciseTime = exTime;
    }
    
    //distance
    bytes = bytes +2;
    uint16_t distance = *(bytes +1);
    distance = distance <<8;
    distance = distance | *bytes;
    if (flag&0x20) {
        pedpmeterData.distance = distance;
    }
    
    //battery
    bytes = bytes +2;
    pedpmeterData.battery = (*bytes)&0x07;
    int temp = *bytes;
    temp = temp>>3;
    pedpmeterData.sleepStatus = temp&0x03;
    temp = temp>>2;
    pedpmeterData.intensityLevel = temp&0x07;
    
    
    return pedpmeterData;
}

/*
 *  厨房秤测量数据解析
 */
+(LSKitchenScaleData*)parseKitchenMeasurementData:(NSData*)data
{
    LSKitchenScaleData *kitchenData = [[LSKitchenScaleData alloc]init];
    uint8_t *bytes = (uint8_t*)[data bytes];
    uint8_t flag = *bytes;
    
    uint8_t flagTemp = flag&0x03;
    switch (flagTemp) {
        case 0:
            kitchenData.unit = [NSString stringWithFormat:@"g"];
            break;
        case 1:
            kitchenData.unit = [NSString stringWithFormat:@"LB OZ"];
            break;
        case 2:
            kitchenData.unit = [NSString stringWithFormat:@"FL OZ"];
            break;
        case 3:
            kitchenData.unit = [NSString stringWithFormat:@"ml"];
            break;
        default:
            break;
    }
    bytes++;
    
    if (flagTemp == 0|| flagTemp == 3) {
        uint16_t temp = *(bytes+1);
        temp = temp <<8;
        temp = temp|*bytes;
        kitchenData.weight = temp;
        bytes = bytes+3;
    }
    
    if (flagTemp == 1|| flagTemp == 2) {
        kitchenData.sectionWeight = *bytes;
        bytes++;
        uint16_t temp = *(bytes+1);
        temp = temp<<8;
        temp = temp|*bytes;
        kitchenData.weight = [self translateSFLOAT:temp];
        bytes = bytes +2;
    }
    
    uint16_t countTime = *(bytes+1);
    countTime = countTime<<8;
    countTime = countTime|*bytes;
    kitchenData.time = countTime;
    
    bytes = bytes+2;
    kitchenData.battery = (*bytes)&0x07;
    
    return kitchenData;
}

/*
 *  身高测量数据解析
 */
+(LSHeightData*)parseHeightMeasurementData:(NSData*)data
{
    LSHeightData *heightData = [[LSHeightData alloc]init];
    uint8_t *bytes = (uint8_t*)[data bytes];
    uint8_t flag = *bytes;
    
    if (flag&0x01) {
        heightData.unit = [NSString stringWithFormat:@"inch"];
    }
    else{
        heightData.unit = [NSString stringWithFormat:@"metre"];
    }
    
    //height
    bytes++;
    uint32_t tempHeight = *(bytes+3);
    tempHeight = tempHeight<<8;
    tempHeight = tempHeight|*(bytes+2);
    tempHeight = tempHeight<<8;
    tempHeight = tempHeight|*(bytes+1);
    tempHeight = tempHeight<<8;
    tempHeight = tempHeight|*bytes;
    heightData.height = [self translateFLOAT:tempHeight];
    
    //utc
    bytes+= 4;
    uint32_t utc = *(bytes +3);
    utc = utc<<8;
    utc = utc|*(bytes+2);
    utc = utc<<8;
    utc = utc|*(bytes+1);
    utc = utc<<8;
    utc = utc|*bytes;
    heightData.date = [LSFormatConverter dateFromUTC:utc];
    heightData.utc=utc;
    //user id
    bytes += 4;
    heightData.userNo = *bytes;
    
    //measurement status
    bytes++;
    
    //battery
    bytes++;
    heightData.battery = (*bytes)&0x07;
    
    return heightData;
}


#pragma mark - private methods

+(double)calculateLbWeightValue:(double)kgWeightValue
{
    double lbWeightValue=0;
    if(kgWeightValue>0)
    {
        int tempValue=(int)(kgWeightValue*10);
        lbWeightValue=2*(((tempValue*11023)+5000)/10000);
        int lbIntegerValue=(int)lbWeightValue;
        lbWeightValue=(double)(lbIntegerValue*0.1);
    }
    return lbWeightValue;
}

+(double)calculateStWeightValue:(double)lbWeightValue
{
    double stWeightValue=0;
    if(lbWeightValue>0)
    {
        int integerNum=(int)lbWeightValue;
        int decimalNum=(int)(lbWeightValue*10-integerNum*10);
        integerNum=integerNum%14;
        decimalNum=decimalNum%14;
        stWeightValue=(integerNum+(0.1*decimalNum));
    }
    return stWeightValue;
}


+(uint32_t)stringToInt32:(NSString*)subString
{
    NSString *lowcaseString = [subString lowercaseString];
    char *characterPoint = (char*)[lowcaseString UTF8String];
    uint32_t result = 0;
    
    for (int i = 0; i<[lowcaseString length]; i++) {
        
        result = result<<4;
        char localChar = *characterPoint;
        uint8_t localInt = 0;
        if (localChar>='0'&&localChar<='9') {
            
            localInt = localChar-'0';
        }
        if (localChar>='a'&&localChar<='f') {
            
            localInt = localChar - 'a' +10;
        }
        result = result |localInt;
        characterPoint++;
    }
    
    return result;
}

+(double)translateToSFloat:(uint16_t)data
{
    double reuslt =0;
    int8_t expent = (data>>12)&0x000f;
    uint16_t temp = data&0x0fff;
    reuslt = temp;
    if (expent > 8) {
        expent = expent -16;
    }
    
    if (expent < 0) {
        int8_t temp = -expent;
        for(int i = 0 ;i < temp; i++)
        {
            reuslt = reuslt/10;
        }
    }
    
    if (expent >0) {
        for(int i = 0; i< expent;i++)
        {
            reuslt = reuslt*10;
        }
    }
    
    return reuslt;
}

+(double)translateSFLOAT:(uint16_t)value
{
    double result = 0;
    int16_t mantissa = value&0x0fff;
    mantissa = mantissa<<4;
    mantissa = mantissa>>4;
    value = value>>12;
    int8_t exponent = value&0x000f;
    
    //exponent = exponent<<4;
    //exponent = exponent>>4;
    if (exponent>8) {
        
        exponent = exponent -16;
    }
    
    result = mantissa;
    if (exponent<0) {
        
        exponent = -exponent;
        
        for (int i = 0; i<exponent; i++) {
            
            result = result/10;
        }
    }else
    {
        
        for (int i = 0; i<exponent; i++) {
            
            result = result*10;
        }
    }
    return result;
}

+(double)translateFLOAT:(uint32_t)value
{
    double result = 0;
    int32_t mantissa = value&0x00ffffff;
    mantissa = mantissa<<8;
    mantissa = mantissa>>8;
    value = value>>24;
    int8_t exponent = value&0x000000ff;
    result = mantissa;
    if (exponent<0) {
        
        exponent = -exponent;
        for (int i = 0; i<exponent; i++) {
            
            result = result/10;
        }
    }else
    {
        for (int i = 0; i<exponent; i++) {
            
            result = result*10;
        }
    }
    
    return result;
    
}

+(NSString *)dateFromUTC:(NSUInteger)utc withTimezone:(int)zone
{
    NSDateComponents *comp= [[NSDateComponents alloc]init];
    [comp setYear:1970];
    [comp setMonth:1];
    [comp setDay:1];
    [comp setHour:0];
    [comp setMinute:0];
    [comp setSecond:0];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    //[calendar setTimeZone:[NSTimeZone timeZoneWithName:@"Pacific/Kwajalein"]];
    NSDate *startDate = [calendar dateFromComponents:comp];
    NSDate *curDate = [NSDate dateWithTimeInterval:(utc + zone * 3600) sinceDate:startDate];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [formatter stringFromDate:curDate];
    
    return dateString;
}

+(NSData *)dataWithString:(NSString *)sendString
{
    sendString = [sendString uppercaseString];
    if ([sendString length] % 2 == 0)
    {
        int bitCount = (int)[sendString length];
        NSMutableData *sendData = [NSMutableData data];
        for (int i = 0; i < bitCount; i+= 2)
        {
            NSString *subString = [sendString substringWithRange:NSMakeRange(i, 2)];
            //字母处理 判断是否有 字母
            BOOL withChar = NO;
            int bufferWithChar = 0;
            for (int r = 0; r < 2; r++)
            {
                NSString *tempString = [subString substringWithRange:NSMakeRange(r, 1)];
                NSData *data = [tempString dataUsingEncoding:NSASCIIStringEncoding];
                char tempBuffer = 0;
                [data getBytes:&tempBuffer];
                if (tempBuffer < 65)
                {
                    bufferWithChar += (r==0?16:1) * (tempBuffer - 48);
                }
                if (tempBuffer >= 65)
                {
                    withChar = YES;
                    bufferWithChar += (r==0?16:1) * (tempBuffer - 55);
                }
            }
            char buffer = 0;
            if (withChar)
            {
                buffer = bufferWithChar;
            }
            else
            {
                buffer = [subString intValue];
                int temp = 6 * (buffer / 10);
                buffer += temp;
            }
            [sendData appendBytes:&buffer length:1];
        }
        return sendData;
    }
    return nil;
}

/*
 * 解析A4设备上传的C9命令，C9表示每小时计步器的统计数据
 */
+(LSPedometerData *)parsePedometerCommandRequestForC9:(NSData *)data  withTimezone:(int)zone
{
    //C9  0001  0000  000171  53CE24C4   F000  FF000009  0002  01F4  07  8A
    if (data.length != 23)
    {
        return nil;
    }
    
    int saveCount = [DataUtilities parserData:data withFormat:DataType_uint16_BIG from:0];
    int notUpdateCount = [DataUtilities parserData:data withFormat:DataType_uint16_BIG from:2];
    
    float step = [DataUtilities parserData:data withFormat:DataType_uint24_BIG from:4];
    int utc = [DataUtilities parserData:data withFormat:DataType_uint32_BIG from:7];
    float examount = [DataUtilities parserData:data withFormat:DataType_SFLOAT_BIG from:11];
    float calories = [DataUtilities parserData:data withFormat:DataType_FLOAT_BIG from:13];
    int exerciseTime = [DataUtilities parserData:data withFormat:DataType_uint16_BIG from:17];
    int distance = [DataUtilities parserData:data withFormat:DataType_uint16_BIG from:19];
    int status = [DataUtilities parserData:data withFormat:DataType_uint8 from:21];
    
    int voltage = [DataUtilities parserData:data withFormat:DataType_uint8 from:22];
    
    LSPedometerData *pedometerData = [[LSPedometerData alloc] init];
    pedometerData.walkSteps = step;
    //    _data.rawData = data;
    //    _data.utc = utc;
    pedometerData.date=[self dateFromUTC:utc withTimezone:zone];
    pedometerData.examount = examount;
    pedometerData.calories = calories;
    pedometerData.exerciseTime = exerciseTime;
    pedometerData.distance = distance;
    // 128 64 32 16 8  4 2  1
    //              0  1 1  1  =  0x07
    //  0  0   0  1 1  0 0  0  =  0x18
    //  1  1   1  0 0  0 0  0  =  0xe0
    pedometerData.battery = status & 0x07;
    pedometerData.sleepStatus = status & 0x18;
    pedometerData.intensityLevel = status & 0xe0;
    pedometerData.voltage = voltage/100.00 + 1.6;
    
    //    NSLog(@"PedometerData save :%d",saveCount);
    //    NSLog(@"PedometerData notUpdateCount :%d",notUpdateCount);
    //    NSLog(@"PedometerData walkSteps:%d",pedometerData.walkSteps);
    //    NSLog(@"PedometerData date:%@",pedometerData.date);
    //    NSLog(@"PedometerData battery:%d",pedometerData.battery);
    
    return pedometerData;
}

/*
 * 解析A4设备上传的CA命令，CA表示每天的总步数
 */
+(LSPedometerData *)parsePedometerCommandRequestForCA:(NSData *)data withTimezone:(int)zone
{
    //CA 00002D  00129E73  F000  FF00 0000   0001  001E  27   8A
    if (data.length != 19)
    {
        return nil;
    }
    float step = [DataUtilities parserData:data withFormat:DataType_uint24_BIG from:0];
    int utc = [DataUtilities parserData:data withFormat:DataType_uint32_BIG from:3];
    float examount = [DataUtilities parserData:data withFormat:DataType_SFLOAT_BIG from:7];
    float calories = [DataUtilities parserData:data withFormat:DataType_FLOAT_BIG from:9];
    int exerciseTime = [DataUtilities parserData:data withFormat:DataType_uint16_BIG from:13];
    int distance = [DataUtilities parserData:data withFormat:DataType_uint16_BIG from:15];
    int status = [DataUtilities parserData:data withFormat:DataType_uint8 from:17];
    
    int voltage = [DataUtilities parserData:data withFormat:DataType_uint8 from:18];
    
    LSPedometerData *pedometerData = [[LSPedometerData alloc] init];
    pedometerData.walkSteps = step;
    //    _data.rawData = data;
    pedometerData.date = [self dateFromUTC:utc withTimezone:zone];
    pedometerData.examount = examount;
    //    _data.utc = utc;
    pedometerData.calories = calories;
    pedometerData.exerciseTime = exerciseTime;
    pedometerData.distance = distance;
    // 128 64 32 16 8  4 2  1
    //              0  1 1  1  =  0x07
    //  0  0   0  1 1  0 0  0  =  0x18
    //  1  1   1  0 0  0 0  0  =  0xe0
    pedometerData.battery = status & 0x07;
    pedometerData.sleepStatus = status & 0x18;
    pedometerData.intensityLevel = status & 0xe0;
    pedometerData.voltage = voltage/100.00 + 1.6;
    
    //    NSLog(@"CA command....................");
    //    NSLog(@"PedometerData walkSteps:%d",pedometerData.walkSteps);
    //    NSLog(@"PedometerData date:%@",pedometerData.date);
    //    NSLog(@"PedometerData battery:%d",pedometerData.battery);
    
    return pedometerData;
}



@end
