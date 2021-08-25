//
//  BleManagerProfiles.h
//  LsBluetooth-Test
//
//  Created by lifesense on 14-8-5.
//  Copyright (c) 2014年 com.lifesense.ble. All rights reserved.
//


#ifndef LsBluetooth_Test_BleManagerProfiles_h
#define LsBluetooth_Test_BleManagerProfiles_h


typedef enum{
    MANAGER_WORK_STATUS_IBLE=0,
    MANAGER_WORK_STATUS_SCAN=1,
    MANAGER_WORK_STATUS_PAIR=2,
    MANAGER_WORK_STATUS_UPLOAD=3,
    MANAGER_WORK_STATUS_CONNECT=4,
}ManagerWorkStatus;


typedef enum
{
    BROADCAST_TYPE_NORMAL=1,
    BROADCAST_TYPE_PAIR=2,
    BROADCAST_TYPE_ALL=3,
}BroadcastType;

typedef enum {
    PAIRED_SUCCESS=1,
    PAIRED_FAILED=2,
}PairedResults;

typedef enum{
    DATA_UPLOAD_SUCCESS=1,
    DATA_UPLOAD_FAILED=2,
} DataUploadResults;



typedef enum{
    CONNECTED_SUCCESS=1,
    CONNECTED_FAILED=2,
    DISCONNECTED=3
} DeviceConnectState;

//测量单位
typedef enum {
    UNIT_KG=0,
    UNIT_LB=1,
    UNIT_ST=2,
}MeasurementUnitType;

////性别类型，1表示男，2表示女
//typedef enum {
//    SEX_MALE=1,
//    SEX_FEMALE=2
//}UserSex;

//性别类型，1表示男，2表示女
typedef enum {
    SEX_MALE=1,
    SEX_FEMALE=2,
}UserSexType;


#endif
