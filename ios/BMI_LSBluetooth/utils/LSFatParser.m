//
//  LSFat.m
//  lifesensehealth1_1
//
//  Created by chris on 14-8-21.
//  Copyright (c) 2014年 lifesense. All rights reserved.
//

#import "LSFatParser.h"

@implementation LSFatParser
//脂肪率计算
+(double)fatByHeigth:(double)height weight:(double)weight imp:(int)imp age:(int)age sex:(UserSexType)sex
{
    imp=imp-10;
    if (sex==SEX_MALE) {
        double fat;
        fat=60.3-486583*height*height/weight/imp+9.146*weight/height/height/imp-251.193*height*height/weight/age+1625303/imp/imp-0.0139*imp+0.05975*age;
        if (fat<5) {
            fat=5;
        }
        return fat;
    }
    if (sex==SEX_FEMALE) {
        double fat;
        fat=57.621-186.422*height*height/weight-382280*height*height/weight/imp+128.005*weight/height/imp-0.0728*weight/height+7816.359/height/imp-3.333*weight/height/height/age;
        if (fat<5) {
            fat=5;
        }
        return fat;
    }
    return 0;
}
//水分含量
+(double)waterByHeigth:(double)height weight:(double)weight imp:(int)imp sex:(UserSexType)sex
{
    imp=imp-10;
    if (sex==SEX_MALE) {
        double water;
        water=30.849+259672.5*height*height/weight/imp+0.372*imp/height/weight-2.581*height*weight/imp;
        return water;
    }
    if (sex==SEX_FEMALE) {
        double water;
        water=23.018+201468.7*height*height/weight/imp+421.543/weight/height+160.445*height/weight;

        return water;
    }
    return 0;
}
//肌肉含量
+(double)muscleByWeight:(double)weight fat:(double)fat sex:(UserSexType)sex
{
    if (sex==SEX_MALE) {
        double muscle;
        muscle=0.95*weight-0.0095*fat*weight-0.13;
        return muscle;
    }
    if (sex==SEX_FEMALE) {
        double muscle;
        muscle=1.13+0.914*weight-0.00914*fat*weight;
        return muscle;
    }
    return 0;
}
//骨质量
+(double)boneByMuscl:(double)muscle sex:(UserSexType)sex
{
    if (sex==SEX_MALE) {
        double bone;
        bone=0.116+0.0525*muscle;
        return bone;
    }
    if (sex==SEX_FEMALE) {
        double bone;
        bone=-1.22+0.0944*muscle;
        return bone;
    }
    return 0;
}
//基础代谢
+(double)basalMetabolismByMuscl:(double)muscle weight:(double)weight age:(int)age sex:(UserSexType)sex
{
    if (sex==SEX_MALE) {
        double basalMetabolism;
        basalMetabolism=-72.421+30.809*muscle+1.795*weight-2.444*age;
        return basalMetabolism;
    }
    if (sex==SEX_FEMALE) {
        double basalMetabolism;
        basalMetabolism=-40.135+25.669*muscle+6.067*weight-1.964*age;

        return basalMetabolism;
    }
    return 0;
}
+(double)calculateBMIWithWeight:(double)weight withHeight:(double)height{
    return (weight / (height * height));
}
@end
