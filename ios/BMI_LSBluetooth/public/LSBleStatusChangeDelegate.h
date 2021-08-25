//
//  LSBleStatusChangeDelegate.h
//  LsBluetooth-Test
//
//  Created by lifesense on 14-8-13.
//  Copyright (c) 2014年 com.lifesense.ble. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LSBleStatusChangeDelegate <NSObject>
@required
-(void)bleConnectorDidBluetoothStatusChange:(NSInteger)bleState;
@end
