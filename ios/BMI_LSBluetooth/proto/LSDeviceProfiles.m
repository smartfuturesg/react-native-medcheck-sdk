//
//  LSDeviceProfiles.m
//  LSBluetooth-Library
//
//  Created by lifesense on 15/8/7.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import "LSDeviceProfiles.h"
#import "LSBleGattServicesConstants.h"

@interface LSDeviceProfiles()

@end

@implementation LSDeviceProfiles

NSString *const SERVICE_UUID_A2_BLOOD_PRESSURE=@"7809";
NSString *const SERVICE_UUID_A3_BLOOD_PRESSURE=@"7889";
NSString *const SERVICE_UUID_COMMAND_START_BLOOD_PRESSURE=@"78E9";
NSString *const SERVICE_UUID_A3_1_BLOOD_PRESSURE=@"7899";

NSString *const SERVICE_UUID_KITCHEN_SCALE=@"780A";
NSString *const SERVICE_UUID_HEIGHT_SCALE=@"7803";

NSString *const SERVICE_UUID_A2_WEIGHT_SCALE=@"7802";
NSString *const SERVICE_UUID_A3_FAT_SCALE=@"7892";
NSString *const SERVICE_UUID_A3_SALTER_FAT_SCALE=@"7882";
NSString *const SERVICE_UUID_GENERIC_FAT_SCALE=@"78B2"; //@"78A2";
NSString *const SERVICE_UUID_A3_1_FAT_SCALE=@"78D2";


NSString *const SERVICE_UUID_A2_PEDOMETER=@"7801";
NSString *const SERVICE_UUID_A4_PEDOMETER=@"A400";
NSString *const SERVICE_UUID_WECHAT_PEDOMETER=@"FEE7";

NSString *const PROTOCOL_TYPE_A2=@"A2";
NSString *const PROTOCOL_TYPE_A3=@"A3";
//NSString *const PROTOCOL_TYPE_A4=@"A4";
NSString *const PROTOCOL_TYPE_A3_1=@"A3_1";

NSString *const PROTOCOL_TYPE_GENERIC_FAT=@"GENERIC_FAT";
NSString *const PROTOCOL_TYPE_KITCHEN=@"KITCHEN_SCALE";
NSString *const PROTOCOL_TYPE_BLOOD_PRESSURE_COMMAND_START=@"COMMAND_START";
NSString *const PROTOCOL_TYPE_WECHAT=@"WECHAT";
NSString *const PROTOCOL_TYPE_GLUCOSE_METER=@"GLUCOSE_METER";


NSString *const KEY_WEIGHT_SCALE_USER_INFO=@"KEY_WEIGHT_SCALE_USER_INFO";
NSString *const KEY_WEIGHT_SCALE_VIBRATION_VOICE=@"KEY_WEIGHT_SCALE_VIBRATION_VOICE";
NSString *const KEY_PEDOMETER_ALARM_CLOCK=@"KEY_PEDOMETER_ALARM_CLOCK";
NSString *const KEY_PEDOMETER_USER_INFO=@"KEY_PEDOMETER_USER_INFO";

NSString *const KEY_DEVICE_TYPE_WEIGHT_SCALE=@"01";
NSString *const KEY_DEVICE_TYPE_FAT_SCALE=@"02";
NSString *const KEY_DEVICE_TYPE_HEIGHT_RULER=@"03";
NSString *const KEY_DEVICE_TYPE_PEDOMETER=@"04";
NSString *const KEY_DEVICE_TYPE_WAIST_RULER=@"05";
NSString *const KEY_DEVICE_TYPE_GLUCOSE_METER=@"06";
NSString *const KEY_DEVICE_TYPE_THERMOMETER=@"07";
NSString *const KEY_DEVICE_TYPE_SPHYGMOMAN_METER=@"08";
NSString *const KEY_DEVICE_TYPE_KITCHEN_SCALE=@"09";


#pragma mark - class methods 

//允许可读的设备信息特征号
+(BOOL)checkingDeviceInfoCharacteristic:(uint16_t)uuidValue
{
    if(uuidValue==DEVICE_MANUFACTURER_CHARACTER
       ||uuidValue==DEVICE_MODEL_NUMBER_CHARACTER
       ||uuidValue==DEVICE_SERIAL_NUMBER_CHARACTER
       ||uuidValue==DEVICE_HARDWARE_VERSION_CHARACTER
       ||uuidValue==DEVICE_SOFTWARE_VERSION_CHARACTER
       ||uuidValue==DEVICE_FIRMWARE_VERSION_CHARACTER)
    {
        return YES;
    }
    else return NO;
    
}

+(NSString *)getProtocolTypeFromServices:(NSString *)serviceUUID
{
    NSString *protocolType=nil;
    if(serviceUUID.length)
    {
        serviceUUID=[serviceUUID uppercaseString];
        protocolType=[[self serviceProtocolMap] objectForKey:serviceUUID];
    }
    return protocolType;
}

+(LSDeviceType)getDeviceTypeFromServices:(NSString *)serviceUUID
{
    if(serviceUUID.length)
    {
        serviceUUID=[serviceUUID uppercaseString];
        NSString * type=[[self serviceDeviceTypeMap] objectForKey:serviceUUID];
        if([type isEqualToString:KEY_DEVICE_TYPE_FAT_SCALE])
        {
            return LS_FAT_SCALE;
        }
        if ([type isEqualToString:KEY_DEVICE_TYPE_PEDOMETER])
        {
            return LS_PEDOMETER;
        }
        if ([type isEqualToString:KEY_DEVICE_TYPE_SPHYGMOMAN_METER])
        {
            return LS_SPHYGMOMETER;
        }
        if ([type isEqualToString:KEY_DEVICE_TYPE_HEIGHT_RULER])
        {
            return LS_HEIGHT_MIRIAM;
        }
        if ([type isEqualToString:KEY_DEVICE_TYPE_KITCHEN_SCALE])
        {
            return LS_KITCHEN_SCALE;
        }
        if ([type isEqualToString:KEY_DEVICE_TYPE_WEIGHT_SCALE])
        {
            return LS_WEIGHT_SCALE;
        }
        if ([type isEqualToString:KEY_DEVICE_TYPE_WAIST_RULER])
        {
            return LS_WAISTLINE_MIRIAM;
        }
        if ([type isEqualToString:KEY_DEVICE_TYPE_GLUCOSE_METER])
        {
            return LS_GLUCOSE_METER;
        }
        if ([type isEqualToString:KEY_DEVICE_TYPE_THERMOMETER])
        {
            return LS_THERMOMETER;
        }
        else return TYPE_UNKONW;
    }
    else return TYPE_UNKONW;
}

+(NSArray *)getGattServicesFromDeviceType:(NSArray *)deviceTypes
{
    if([deviceTypes count])
    {
        NSMutableArray *gattServices=[[NSMutableArray alloc] init];
        for (id type in deviceTypes)
        {
            NSInteger typeInteger = 2;
            if ([type isKindOfClass:[NSArray class]]) {
                if ([type count] > 0) {
                    typeInteger = [[type objectAtIndex:0] integerValue];
                }
            }
            
            switch (typeInteger) {
                case LS_WEIGHT_SCALE:
                {
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",WEIGHTSCALE_SERVICE_UUID]]];
                }break;
                case LS_PEDOMETER:
                {
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",PEDOMETER_SERVICE_UUID]]];
//                     [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",PEDOMETER_SERVICE_UUID_A4]]];
                    
                }break;
                case LS_SPHYGMOMETER:
                {
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",BLOODPRESSURE_SERVICE_UUID]]];
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",BLOODPRESSURE_A3_SERVICE_UUID]]];
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",BLOODPRESSURE_COMMAND_START_SERVICE_UUID]]];
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",BLOODPRESSURE_A3_PHILIPS_SERVICE_UUID]]];
                }break;
                case LS_KITCHEN_SCALE:
                {
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x", KITCHENSCALE_SERVICE_UUID]]];
                    
                } break;
                case LS_HEIGHT_MIRIAM:
                {
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x", HEIGHT_SERVICE_UUID]]];
                } break;
                case LS_FAT_SCALE:
                {
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",FAT_SCALE_A3_SERVICE_UUID]]];
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",FAT_SCALE_A3_SALTER_SERVICE_UUID]]];
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",FAT_SCALE_A3_PHILIPS_SERVICE_UUID]]];
                    [gattServices addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%x",GENERIC_FAT_SCALE_SERVICE_UUID]]];
                }break;
            }
            
        }
        return gattServices;
    }
    else return nil;
    
}

+(NSInteger)getServiceUuidByDeviceType:(LSDeviceType)deviceType protocolType:(NSString *)protocolType;
{
    if(protocolType.length==0 || deviceType==TYPE_UNKONW)
    {
        
        return 0;
    }
    else if([protocolType isEqualToString:@"A2"])
    {
        if(deviceType==LS_WEIGHT_SCALE)
        {
            return WEIGHTSCALE_SERVICE_UUID;
        }
        else if (deviceType==LS_HEIGHT_MIRIAM)
        {
            return HEIGHT_SERVICE_UUID;
        }
        else if (deviceType==LS_PEDOMETER)
        {
            return PEDOMETER_SERVICE_UUID;
        }
        else if (deviceType==LS_SPHYGMOMETER)
        {
            return BLOODPRESSURE_SERVICE_UUID;
        }
        else return 0;
        
    }
    else if([protocolType isEqualToString:@"A3"])
    {
        
        if(deviceType==LS_FAT_SCALE)
        {
            return FAT_SCALE_A3_SERVICE_UUID;
        }
        else if(deviceType==LS_SPHYGMOMETER)
        {
            return BLOODPRESSURE_A3_SERVICE_UUID;
        }
        else return 0;
    }
    else if([protocolType isEqualToString:@"GENERIC_FAT"])
    {
        
        if(deviceType==LS_FAT_SCALE)
        {
            return GENERIC_FAT_SCALE_SERVICE_UUID;
        }
        
        else return 0;
    }
    else if([protocolType isEqualToString:@"KITCHEN_SCALE"])
    {
        if(deviceType==LS_KITCHEN_SCALE)
        {
            return KITCHENSCALE_SERVICE_UUID;
        }
        else return 0;
    }
    else if ([protocolType isEqualToString:@"SALTER_MIBODY"])
    {
        if (deviceType==LS_FAT_SCALE)
        {
            return FAT_SCALE_A3_SALTER_SERVICE_UUID;
        }
        else return 0;
    }
    else if ([protocolType isEqualToString:@"COMMAND_START"])
    {
        if (deviceType==LS_SPHYGMOMETER)
        {
            return BLOODPRESSURE_COMMAND_START_SERVICE_UUID;
        }
        else return 0;
    }
    else if ([protocolType isEqualToString:@"A3_1"])
    {
        if (deviceType==LS_FAT_SCALE)
        {
            return FAT_SCALE_A3_PHILIPS_SERVICE_UUID;
        }
        if(deviceType==LS_SPHYGMOMETER)
        {
            return BLOODPRESSURE_A3_PHILIPS_SERVICE_UUID;
        }
        else return 0;
    }
//    else if ([protocolType isEqualToString:@"A4"])
//    {
//        if(deviceType==LS_PEDOMETER)
//        {
//            return PEDOMETER_SERVICE_UUID_A4;
//        }
//        else return 0;
//    }
    else return 0;
    
    
}


#pragma mark - all device service uuid

+(NSMutableDictionary *)serviceProtocolMap
{
    NSMutableDictionary *protocolMap=[[NSMutableDictionary alloc] init];
    //A2 protocol service
    [protocolMap setValue:PROTOCOL_TYPE_A2 forKey:SERVICE_UUID_A2_BLOOD_PRESSURE];
    [protocolMap setValue:PROTOCOL_TYPE_A2 forKey:SERVICE_UUID_A2_WEIGHT_SCALE];
    [protocolMap setValue:PROTOCOL_TYPE_A2 forKey:SERVICE_UUID_A2_PEDOMETER];
    [protocolMap setValue:PROTOCOL_TYPE_A2 forKey:SERVICE_UUID_HEIGHT_SCALE];
    
    //A3 protocol service
    [protocolMap setValue:PROTOCOL_TYPE_A3 forKey:SERVICE_UUID_A3_BLOOD_PRESSURE];
    [protocolMap setValue:PROTOCOL_TYPE_A3 forKey:SERVICE_UUID_A3_FAT_SCALE];
    [protocolMap setValue:PROTOCOL_TYPE_A3 forKey:SERVICE_UUID_A3_SALTER_FAT_SCALE];
    
    //A4 protocol service
//    [protocolMap setValue:PROTOCOL_TYPE_A4 forKey:SERVICE_UUID_A4_PEDOMETER];
    
    //generic fat protocol service
    [protocolMap setValue:PROTOCOL_TYPE_GENERIC_FAT forKey:SERVICE_UUID_GENERIC_FAT_SCALE];
    
    [protocolMap setValue:PROTOCOL_TYPE_KITCHEN forKey:SERVICE_UUID_KITCHEN_SCALE];
    
    [protocolMap setValue:PROTOCOL_TYPE_BLOOD_PRESSURE_COMMAND_START forKey:SERVICE_UUID_COMMAND_START_BLOOD_PRESSURE];
    
    //A3.1 protocol service
    [protocolMap setValue:PROTOCOL_TYPE_A3_1 forKey:SERVICE_UUID_A3_1_BLOOD_PRESSURE];
    [protocolMap setValue:PROTOCOL_TYPE_A3_1 forKey:SERVICE_UUID_A3_1_FAT_SCALE];

    
    return protocolMap;
}

+(NSDictionary *)serviceDeviceTypeMap
{
    
    NSMutableDictionary *deviceTypeMap=[[NSMutableDictionary alloc] init];
    //A2 protocol service
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_SPHYGMOMAN_METER forKey:SERVICE_UUID_A2_BLOOD_PRESSURE];
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_WEIGHT_SCALE forKey:SERVICE_UUID_A2_WEIGHT_SCALE];
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_PEDOMETER forKey:SERVICE_UUID_A2_PEDOMETER];
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_HEIGHT_RULER forKey:SERVICE_UUID_HEIGHT_SCALE];
    
    //A3 protocol service
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_SPHYGMOMAN_METER forKey:SERVICE_UUID_A3_BLOOD_PRESSURE];
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_FAT_SCALE forKey:SERVICE_UUID_A3_FAT_SCALE];
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_FAT_SCALE forKey:SERVICE_UUID_A3_SALTER_FAT_SCALE];
    
    //A4 protocol service
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_PEDOMETER forKey:SERVICE_UUID_A4_PEDOMETER];
    
    //generic fat protocol service
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_FAT_SCALE forKey:SERVICE_UUID_GENERIC_FAT_SCALE];
    
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_KITCHEN_SCALE forKey:SERVICE_UUID_KITCHEN_SCALE];
    
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_SPHYGMOMAN_METER forKey:SERVICE_UUID_COMMAND_START_BLOOD_PRESSURE];
    
    //A3.1 protocol service
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_SPHYGMOMAN_METER forKey:SERVICE_UUID_A3_1_BLOOD_PRESSURE];
    [deviceTypeMap setValue:KEY_DEVICE_TYPE_FAT_SCALE forKey:SERVICE_UUID_A3_1_FAT_SCALE];

    return deviceTypeMap;

    
}
@end
