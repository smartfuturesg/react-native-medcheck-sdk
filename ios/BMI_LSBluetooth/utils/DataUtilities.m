
#import "DataUtilities.h"

@implementation DataUtilities
int uintValue(NSData *data,NSInteger begin,NSInteger length);
int sint8Value(NSData *data,NSInteger begin);
float sfloatValue(NSData*data,int begin);
float floatValue(NSData *data,int begin);

+ (int)sizeOfFormatWithFormatString:(NSString *)type  data:(NSData *)data {
    int size = 0;
    if ([type isEqualToString:@"utf8s"]) {
        size = data.length / 2;
    }
    
    else if ([type isEqualToString:@"8bit"]) {
        return 1;
    }
    
    else if ([type isEqualToString:@"16bit"]) {
        return 2;
    }
    
    else if ([type isEqualToString:@"uint8"]) {
        size = 1;
    }
    else if ([type isEqualToString:@"uint16"]) {
        size = 2;
    }
    else if ([type isEqualToString:@"uint24"]) {
        size = 3;
    }
    else if ([type isEqualToString:@"uint32"]) {
        size = 4;
    }
    else if ([type isEqualToString:@"uint40"]) {
        size = 5;
    }
    else if ([type isEqualToString:@"SFLOAT"]) {
        size = 2;
    }
    else if ([type isEqualToString:@"FLOAT"]) {
        size = 4;
    }
    return size;
}

+(id)parserData:(NSData*)data withFormatString:(NSString *)type from:(NSInteger)begin {
    float returnfloat = 0;
    if ([type isEqualToString:@"utf8s"]) {
        return [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(begin, data.length - begin)] encoding:NSASCIIStringEncoding];
    }
    
    if ([type isEqualToString:@"8bit"]) {
        return bitString(data,1);
    }
    
    if ([type isEqualToString:@"16bit"]) {
        return bitString(data,2);
    }
    
    else if ([type isEqualToString:@"uint8"]) {
        returnfloat = [DataUtilities parserData:data withFormat:DataType_uint8 from:begin];
    }
    else if ([type isEqualToString:@"uint16"]) {
        returnfloat = [DataUtilities parserData:data withFormat:DataType_uint16 from:begin];
        
    }
    else if ([type isEqualToString:@"uint24"]) {
        returnfloat = [DataUtilities parserData:data withFormat:DataType_uint24 from:begin];
        
    }
    else if ([type isEqualToString:@"uint32"]) {
        returnfloat = [DataUtilities parserData:data withFormat:DataType_uint32 from:begin];
        
    }
    else if ([type isEqualToString:@"uint40"]) {
        returnfloat = [DataUtilities parserData:data withFormat:DataType_uint40 from:begin];
        
    }
    else if ([type isEqualToString:@"SFLOAT"]) {
        returnfloat = [DataUtilities parserData:data withFormat:DataType_SFLOAT from:begin];
        
    }
    else if ([type isEqualToString:@"FLOAT"]) {
        returnfloat = [DataUtilities parserData:data withFormat:DataType_FLOAT from:begin];
        
    }
    return [NSNumber numberWithFloat:returnfloat];
}

+(NSData *)parserObject2Data:(NSNumber *)object withFormatString:(DataType)type {
    if (!object) {
        return nil;
    }
    switch (type) {
        case DataType_utf8s: {
            NSString *tempString = (NSString *)object;
            return [tempString dataUsingEncoding:NSASCIIStringEncoding];
        }
            break;
        case DataType_uint8:
            return uintData(object.intValue, 1);
            break;
        case DataType_uint16:
            return uintData(object.intValue, 2);
            break;
        case DataType_uint24:
            return uintData(object.intValue, 3);
            
            break;
        case DataType_uint32:
            return uintData(object.intValue, 4);
            break;
        case DataType_uint40:
            return uintData(object.intValue, 5);
            
            break;
        case DataType_SFLOAT:
            return sfloatData(object.floatValue);
            break;
        case DataType_FLOAT:
            return floatData(object.floatValue);
            break;
        case DataType_FLOAT_BIG:
            return bigFloatData(object.floatValue);
            break;
        case DataType_uint32_BIG:
            return bigUintData(object.intValue,4);
            
        case DataType_uint24_BIG:
            return bigUintData(object.intValue,3);
            
        case DataType_uint16_BIG:
            return bigUintData(object.intValue,2);
            
            break;
        default:
            break;
    }
    
    return nil;
}

+(double)parserData:(NSData*)data withFormat:(DataType)type from:(NSInteger)begin {
    switch (type) {
        case DataType_uint8:
            return uintValue(data, begin, 1);
            break;
        case DataType_uint16:
            return uintValue(data, begin, 2);
            break;
        case DataType_uint24:
            return uintValue(data, begin, 3);
            break;
        case DataType_uint32:
            return uintValue(data, begin, 4);
            break;
        case DataType_uint40:
            return uintValue(data, begin, 5);
            break;
        case DataType_SFLOAT:
            return sfloatValue(data,begin);
            break;
        case DataType_FLOAT:
            return floatValue(data,begin);
            break;
        case DataType_SFLOAT_BIG:
            return bigSFloatValue(data,begin);
            break;
        case DataType_FLOAT_BIG:
            return bigFloatValue(data,begin);
            break;
        case DataType_uint32_BIG:
            return bigIntValue(data,begin, 4);
            
        case DataType_uint24_BIG:
            return bigIntValue(data,begin, 3);
            break;
        case DataType_uint16_BIG:
            return bigIntValue(data,begin, 2);
            break;
        case DataType_sint8:
            return sint8Value(data,begin);
            break;
        default:
            break;
    }
    return 0;
    
}

NSString*getDate(NSData*receiveData,int index) {
    int year = 0;
    [receiveData getBytes:&year range:NSMakeRange(0+index, 2)];
    int month = 0;
    [receiveData getBytes:&month range:NSMakeRange(2+index, 1)];
    int day = 0;
    [receiveData getBytes:&day range:NSMakeRange(3+index, 1)];
    int hours = 0;
    [receiveData getBytes:&hours range:NSMakeRange(4+index, 1)];
    int minutes = 0;
    [receiveData getBytes:&minutes range:NSMakeRange(5+index, 1)];
    int seconds = 0;
    [receiveData getBytes:&seconds range:NSMakeRange(6+index, 1)];
    NSString *dateString = [NSString stringWithFormat:@"%d:%d:%d %d/%d/%d",hours,minutes,seconds,day,month,year];
    return dateString;
    
}

NSData * dataWithString(NSString *sendString) {
    sendString = [sendString uppercaseString];
    if ([sendString length] % 2 == 0) {
        int bitCount = (int)[sendString length];
        NSMutableData *sendData = [NSMutableData data];
        for (int i = 0; i < bitCount; i+= 2) {
            NSString *subString = [sendString substringWithRange:NSMakeRange(i, 2)];
            //字母处理 判断是否有 字母
            BOOL withChar = NO;
            int bufferWithChar = 0;
            for (int r = 0; r < 2; r++) {
                NSString *tempString = [subString substringWithRange:NSMakeRange(r, 1)];
                NSData *data = [tempString dataUsingEncoding:NSASCIIStringEncoding];
                char tempBuffer = 0;
                [data getBytes:&tempBuffer];
                if (tempBuffer < 65) {
                    bufferWithChar += (r==0?16:1) * (tempBuffer - 48);
                }
                if (tempBuffer >= 65) {
                    withChar = YES;
                    bufferWithChar += (r==0?16:1) * (tempBuffer - 55);
                }
            }
            char buffer = 0;
            if (withChar) {
                buffer = bufferWithChar;
            } else {
                buffer = [subString intValue];
                int temp = 6 * (buffer / 10);
                buffer += temp;
            }
            [sendData appendBytes:&buffer length:1];
        }
        //        NSLog(@"sendData %@",sendData);
        return sendData;
    }
    return nil;
}

NSString *stringWithData(NSData *data) {
    NSString *dataString = [data description];
    dataString = [dataString stringByReplacingOccurrencesOfString:@" " withString:@""];
    dataString = [dataString stringByReplacingOccurrencesOfString:@"<" withString:@""];
    dataString = [dataString stringByReplacingOccurrencesOfString:@">" withString:@""];
    return dataString;
    
}

NSString *bitString(NSData *data,int size) {
    NSMutableString *bitString = [NSMutableString string];
    if (data.length >= 1) {
        int byteValue = 0;
        [data getBytes:&byteValue length:1];
        int length = size * 8;
        for (int i = length - 1; i >= 0; i --) {
            [bitString appendFormat:@"%d",getBit(byteValue, i)];
        }
    }
    return bitString;
    
}

int getBit(int byte,int index) {
    int get = 0;
    get = byte & (0x01 << index);
    get = get >> index;
    return get;
}

int getTwoBit(int byte,int index) {
    int get = 0;
    get = byte & (0x03 << index);
    get = get >> index;
    return get;
}

int uintValue(NSData *data,NSInteger begin,NSInteger length) {
    int temp = 0;
    if (data.length >= length + begin) {
        [data getBytes:&temp range:NSMakeRange(begin, length)];
    }
    return temp;
}

NSData *uintData(int value ,NSInteger length) {
    return [NSData dataWithBytes:&value length:length];
}
NSData *bigUintData(int value ,NSInteger length) {
    NSMutableData *data = [NSMutableData new];
    for (int i = length - 1; i >= 0; i --) {
        int temp = (value >> (i*8) & 0xff);
        [data appendBytes:&temp length:1];
    }
    return data;
}

int sint8Value(NSData *data,NSInteger begin) {
    if (data.length < begin + 1) {
        return 0;
    }
    SInt8 value = 0;
    [data getBytes:&value range:NSMakeRange(begin, 1)];
    return value;
}

NSData *sintData(SInt8 value) {
    return [NSData dataWithBytes:&value length:1];
}

float sfloatValue(NSData*data,int begin) {
    if (data.length < begin + 2) {
        return 0;
    }
    int get = 0;
    int temp = 0;
    float result = 0;
    [data getBytes:&get range:NSMakeRange(begin, 2)];
    temp = get & 0xf000;
    temp = temp  >> 12;
    if (temp >= 8) {
        temp -= 16;
    }
    get &= 0x0fff;
    result = get;
    for (int i = 0; i < abs(temp); i++) {
        if (temp >0) {
            result *= 10;
        } else {
            result /= 10;
        }
    }
    return result;
}

NSData *sfloatData(float value) {
    NSMutableData *resultData = [[NSMutableData alloc] init];
#if __has_feature(objc_arc)
#else
    [resultData autorelease];
#endif
    int zeroPoint = 0;
    int hight = 0;
    int low = 0;
    float temp = value * 10;
    zeroPoint = 15;
    int tempInt = (int)temp;
    hight = (tempInt & 0x0f00) / 256;
    low = tempInt & 0xff;
    [resultData appendBytes:&low length:1];
    hight = (zeroPoint*16) + hight;
    [resultData appendBytes:&hight length:1];
    return resultData;
}

float floatValue(NSData *receiveData,int begin) {
    if (receiveData.length < begin + 4) {
        return 0;
    }
    int get = 0;
    int temp = 0;
    float result = 0;
    
    if ([receiveData length] == 4) {
        [receiveData getBytes:&get range:NSMakeRange(0+begin, 3)];
        [receiveData getBytes:&temp range:NSMakeRange(3+begin, 1)];
        result = get;
        if (temp > 128) {
            temp -= 256;
        }
        for (int i = 0; i < abs(temp); i++) {
            if (temp >0) {
                result *= 10;
            } else {
                result /= 10;
            }
        }
    }
    return result;
}

int bigIntValue(NSData *receiveData,int begin,int byteCount) {
    if (receiveData.length < begin+byteCount) {
        return 0;
    }
    NSData *temp = [receiveData subdataWithRange:NSMakeRange(begin, byteCount)];
    int get = 0;
    int result = 0;
    for (int i = 0; i < byteCount; i ++) {
        [temp getBytes:&get range:NSMakeRange(i, 1)];
        result += get * pow(256, byteCount - i - 1);
    }
    return result;
}

float bigSFloatValue(NSData *receiveData,int begin) {
    if (receiveData.length < begin + 2) {
        return 0;
    }
    int temp = 0;
    
    float result = 0;
    
    if ([receiveData length] >= 2) {
        [receiveData getBytes:&temp range:NSMakeRange(0+begin, 1)];
        result = (float)bigIntValue(receiveData,begin,2);
        temp = temp >> 4;
        result = ((int)result & 0x0fff);
        if (temp > 8) {
            temp -= 16;
        }
        for (int i = 0; i < abs(temp); i++) {
            if (temp >0) {
                result *= 10;
            } else {
                result /= 10;
            }
        }
    }
    return result;
}

float bigFloatValue(NSData *receiveData,int begin) {
    if (receiveData.length < begin + 4) {
        return 0;
    }
    int temp = 0;
    
    float result = 0;
    
    if ([receiveData length] >= 4) {
        [receiveData getBytes:&temp range:NSMakeRange(0+begin, 1)];
        result = (float)bigIntValue(receiveData,1+begin,3);
        if (temp > 128) {
            temp -= 256;
        }
        for (int i = 0; i < abs(temp); i++) {
            if (temp >0) {
                result *= 10;
            } else {
                result /= 10;
            }
        }
    }
    return result;
}


NSData *floatData(float value) {
    //错误处理
    //最多只保留小数后两位
    int tempValue = value * 100;
    value = tempValue / 100;
    
    NSMutableData *resultData = [[NSMutableData alloc] init];
#if __has_feature(objc_arc)
#else
    [resultData autorelease];
#endif
    int zeroPoint = 0;
    int hight = 0;
    int low = 0;
    float temp = value;
    while (temp != floorf(temp)) {
        temp *= 10;
        zeroPoint --;
        if (zeroPoint == -1) {
            zeroPoint = 255;
        }
    }
    if (zeroPoint == 0 && temp != 0) {
        temp *= 10;
        zeroPoint --;
    }
    int tempInt = (int)temp;
    hight = (tempInt & 0xff0000) >> 16;
    low = tempInt * 0x00ffff;
    [resultData appendBytes:&tempInt length:2];
    [resultData appendBytes:&hight length:1];
    [resultData appendBytes:&zeroPoint length:1];
    return resultData;
}

NSData *bigFloatData(float value) {
    //错误处理
    //最多只保留小数后两位
    int tempValue = value * 100;
    int head = 0xfe;
    NSData *headData = [NSData dataWithBytes:&head length:1];
    NSData *intValueData = bigUintData(tempValue, 3);
    
    NSMutableData *resultData = [[NSMutableData alloc] init];
#if __has_feature(objc_arc)
#else
    [resultData autorelease];
#endif
    [resultData appendData:headData];
    [resultData appendData:intValueData];
    return resultData;
}

NSString *getStringWithUUID(CBUUID *uuid) {
    NSMutableString *string = [[NSMutableString alloc] init] ;
#if __has_feature(objc_arc)
#else
    [string autorelease];
#endif
    NSString *temp = nil;
    switch (uuid.data.length) {
        case 16:{
            temp = [uuid.data.description substringWithRange:NSMakeRange(1, 8)];
            [string appendFormat:@"%@-",temp];
            temp = [uuid.data.description substringWithRange:NSMakeRange(10, 4)];
            [string appendFormat:@"%@-",temp];
            temp = [uuid.data.description substringWithRange:NSMakeRange(14, 4)];
            [string appendFormat:@"%@-",temp];
            temp = [uuid.data.description substringWithRange:NSMakeRange(19, 4)];
            [string appendFormat:@"%@-",temp];
            temp = [uuid.data.description substringWithRange:NSMakeRange(23, 4)];
            [string appendFormat:@"%@",temp];
            temp = [uuid.data.description substringWithRange:NSMakeRange(28, 8)];
            [string appendFormat:@"%@",temp];
        }
            break;
        case 2:{
            temp = [uuid.data.description substringWithRange:NSMakeRange(1, 4)];
            [string appendFormat:@"%@",temp];
        }
            break;
        default:
            break;
    }
    return string.uppercaseString;
}


@end
