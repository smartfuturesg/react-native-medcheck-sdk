//
//  LSBleCommandProfiles.m
//  LSBluetooth-Library
//
//  Created by lifesense on 15/7/27.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import "LSBleCommandProfiles.h"
#import "LSFormatConverter.h"
#import "LSBleGattServicesConstants.h"
#import "LSFormatConverter.h"

@implementation LSBleCommandProfiles


+(NSData *)getUtcCommand
{
    uint8_t value[20]={0};
    value[0]=UTC_COMMAND;
    uint32_t utc = [LSFormatConverter currentUTC];
    value[1]=utc&0xff;
    utc= utc>>8;
    value[2]= utc&0xff;
    utc=utc>>8;
    value[3]=utc&0xff;
    utc=utc>>8;
    value[4]=utc&0xff;
    return [NSData dataWithBytes:value length:5];
}

+(NSData *)getDisconnectCommand
{
    uint8_t value[20]={0};
    value[0] = DISCONNECT_COMMAND;
    return [NSData dataWithBytes:value length:1];
}

+(NSData *)getBroadcastIdCommand:(NSString *)broadcastId command:(NSString *)command
{
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= broadcastId.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [broadcastId substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

+(NSData *)getBroadcastIdCommand:(NSString *)broadcastId
{
    NSMutableData* data = [NSMutableData data];
    Byte command=0x21;
    [data appendBytes:&command length:1];
    
    int idx;
    for (idx = 0; idx+2 <= broadcastId.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [broadcastId substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
    
    
}

+(NSData *)getXorResultsCommand:(NSString *)password randomNumber:(uint32_t)randomNumber
{
    uint8_t value[20]={0};
    value[0]=RESULT_COMMAND;
    NSUInteger tempPassword=[LSFormatConverter hexStringUnsignedInteger:password];
    uint32_t result = randomNumber^(tempPassword);
    for (int i = 1; i<5; i++)
    {
        value[i]=result&0xff;
        result=result>>8;
    }
    return [NSData dataWithBytes:value length:5];
}

+(NSData *)getBindingUserNameCommand:(NSUInteger)userNumber name:(NSString *)userName
{
    if(userNumber==0||userName.length==0)
    {
        return nil;
    }
    /*
    uint8_t value[18] = {0};
    value[0] = USER_NAME_COMMAND;
    int count = 1;
    value[count++] = userNumber;//
    NSData *temp = [userName dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t *name = (uint8_t*)[temp bytes];
    for(int i=0;i<temp.length;i++)
    {
        value[count++] = name[i];
    }
    for(int i=temp.length+1;i<17;i++)
    {
        value[count++] =0x20;
    }
    
    NSData *tempdata = [NSData dataWithBytes:value length:count];
    return tempdata;
    */
    
    /**
     * Added in version 3.0.8
     */
    NSUInteger cmd=USER_NAME_COMMAND;
    NSMutableData *mutableData=[[NSMutableData alloc] initWithCapacity:18];
    //填充命令号
    [mutableData appendData:[NSData dataWithBytes:&cmd length:1]];
    //填充userNumber
    [mutableData appendData:[NSData dataWithBytes:&userNumber length:1]];
    NSData *userNameData=[userName dataUsingEncoding:NSUTF8StringEncoding];
    if(userNameData.length > 16)
    {
        userNameData=[userNameData subdataWithRange:NSMakeRange(0, 16)];
        //填充数据
        [mutableData appendData:userNameData];
    }
    else
    {
        NSUInteger dataLength=userNameData.length;
        //填充数据
        [mutableData appendData:userNameData];
        for(int i=0;i<(16-dataLength);i++)
        {
            NSUInteger space=0x20;
            //长度不足15个字节，填充0x20
            [mutableData appendBytes:&space length:1];
        }
    }
    return [[NSData alloc] initWithData:mutableData];
    
}

@end
