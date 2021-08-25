//
//  LSPedometerAlarmClock.m
//  LsBluetooth-Test
//
//  Created by lifesense on 14-8-15.
//  Copyright (c) 2014年 com.lifesense.ble. All rights reserved.
//

#import "LSPedometerAlarmClock.h"

@implementation LSPedometerAlarmClock
-(id)init
{
    if (self=[super init]) {
        _command=0x42;
        _flag=7;
    }
    
    return self;
}

-(NSData*)getData
{
    int8_t array[]={_command,_flag,
        _switch1,_day1,_hour1,_minute1,
        _switch2,_day2,_hour2,_minute2,
        _switch3,_day3,_hour3,_minute3,
        _switch4,_day4,_hour4,_minute4
    };
    NSData*data=[NSData dataWithBytes:array length:18];
    return data;
}
-(NSString *)description
{
    NSString*str;
    str=[NSString stringWithFormat:@"%d,%d,\n---%d,%d,%d,%d,\n---%d,%d,%d,%d,\n---%d,%d,%d,%d,\n---%d,%d,%d,%d",_command,_flag,
         _switch1,_day1,_hour1,_minute1,
         _switch2,_day2,_hour2,_minute2,
         _switch3,_day3,_hour3,_minute3,
         _switch4,_day4,_hour4,_minute4];
    return str;
}

@end
