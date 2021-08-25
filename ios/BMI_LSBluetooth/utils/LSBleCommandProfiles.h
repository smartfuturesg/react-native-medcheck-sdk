//
//  LSBleCommandProfiles.h
//  LSBluetooth-Library
//
//  Created by lifesense on 15/7/27.
//  Copyright (c) 2015年 Lifesense. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSBleCommandProfiles : NSObject

+(NSData *)getUtcCommand;

+(NSData *)getDisconnectCommand;

+(NSData *)getXorResultsCommand:(NSString *)password randomNumber:(uint32_t)randomNumber;

+(NSData *)getBindingUserNameCommand:(NSUInteger)userNumber name:(NSString *)userName;

+(NSData *)getBroadcastIdCommand:(NSString *)broadcastId;

+(NSData *)getBroadcastIdCommand:(NSString *)broadcastId command:(NSString *)command;


@end
