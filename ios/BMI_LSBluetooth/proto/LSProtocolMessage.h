//
//  LSProtocolMessage.h
//  LSBluetooth-Library
//
//  Created by lifesense on 15/7/9.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSProtocolWorkflow.h"

@interface LSProtocolMessage : NSObject

@property(nonatomic)ProtocolWorkflow operatingDirective;
@property(nonatomic,strong)NSData *commandData;

@end
