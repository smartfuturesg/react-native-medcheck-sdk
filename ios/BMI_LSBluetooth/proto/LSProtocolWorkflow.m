//
//  LSProtocolWorkflow.m
//  LSBluetooth-Library
//
//  Created by lifesense on 15/8/5.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import "LSProtocolWorkflow.h"

@implementation LSProtocolWorkflow

+(NSString *)enumToString:(ProtocolWorkflow)enumValue
{
    NSString *stringValue=nil;
    stringValue=[[self protocolWorkflowArray] objectAtIndex:enumValue];
    stringValue=[stringValue lowercaseString];
    return stringValue;
}

+(NSArray *)protocolWorkflowArray
{
    return @[
             @"OPERATING_UNKNOWN",
             @"OPERATING_FREE",
             @"OPERATING_CONNECT_DEVICE",
             @"OPERATING_READ_DEVICE_INFO",
             @"OPERATING_RECEIVE_PASSWORD",
             @"OPERATING_SET_NOTIFY_FOR_CHARACTERISTICS",
             @"OPERATING_SET_NOTIFY_FOR_DESCRIPTOR",
             
             @"OPERATING_WRITE_BROADCAST_ID",
             @"OPERATING_RECEIVE_RANDOM_NUMBER",
             @"OPERATING_WRITE_XOR_RESULTS",
             @"OPERATING_WRITE_BIND_USER_NUMBER",
             @"OPERATING_WRITE_UNBIND_USER_NUMBER",
             @"OPERATING_WRITE_USER_INFO",
             @"OPERATING_WRITE_ALARM_CLOCK",
             @"OPERATING_WRITE_UTC_TIME",
             @"OPERATING_WRITE_DISCONNECT",
             @"OPERATING_PAIRED_RESULTS_PROCESS",
             @"OPERATING_UPLOADED_RESULTS_PROCESS",
             
             @"OPERATING_SET_INDICATE_FOR_CHARACTERISTICS",
             @"OPERATING_WRITE_AUTH_RESPONSE",
             @"OPERATING_WRITE_INIT_RESPONSE",
             @"OPERATING_WAITING_TO_RECEIVE_DATA",
             @"OPERATING_WRITE_C7_COMMAND_TO_DEVICE",
             @"OPERATING_WRITE_C4_COMMAND_TO_DEVICE",
             @"OPERATING_WRITE_C9_COMMAND_TO_DEVICE",
             @"OPERATING_WRITE_CA_COMMAND_TO_DEVICE",
             @"OPERATING_WRITE_CB_COMMAND_TO_DEVICE",
             @"OPERATING_WRITE_CE_COMMAND_TO_DEVICE",
             @"OPERATING_WRITE_CC_COMMAND_TO_DEVICE",
             @"OPERATING_WRITE_C3_COMMAND_TO_DEVICE",
             
             @"OPERATING_WRITE_VIBRATION_VOICE",
             @"OPERATING_WRITE_CURRENT_STATE_FOR_PEDOMETER_A2",
             @"OPERATING_SET_NOTIFY_FOR_KITCHEN_SCALE",
             
            
             @"OPERATING_WRITE_START_MEASURE_COMMAND_TO_DEVICE",
             @"OPERATING_WRITE_USER_MESSAGE_TO_PEDOMETER",
             @"OPERATING_WRITE_CURRENT_STATE_TO_PEDOMETER",
             @"OPERATING_WRITE_TARGET_STATE_TO_PEDOMETER",
             @"OPERATING_WRITE_UNIT_CONVERSION_TO_PEDOMETER",
             
             @"OPERATING_WRITE_BROADCAST_ID_ON_SYNC"];
}
@end
