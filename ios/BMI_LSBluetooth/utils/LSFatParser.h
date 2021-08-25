//
//  LSFat.h
//  lifesensehealth1_1
//
//  Created by chris on 14-8-21.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "BleManagerProfiles.h"

@interface LSFatParser : NSObject
//脂肪率计算
+(double)fatByHeigth:(double)height weight:(double)weight imp:(int)imp age:(int)age sex:(UserSexType)sex;
//水分含量
+(double)waterByHeigth:(double)height weight:(double)weight imp:(int)imp sex:(UserSexType)sex;
//肌肉含量
+(double)muscleByWeight:(double)weight fat:(double)fat sex:(UserSexType)sex;
//骨质量
+(double)boneByMuscl:(double)muscle sex:(UserSexType)sex;
//基础代谢
+(double)basalMetabolismByMuscl:(double)muscle weight:(double)weight age:(int)age sex:(UserSexType)sex;

+(double)calculateBMIWithWeight:(double)weight withHeight:(double)height;
@end
