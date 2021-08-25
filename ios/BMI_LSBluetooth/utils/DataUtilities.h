
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface DataUtilities : NSObject

typedef NS_ENUM(NSInteger, DataType) {
    DataType_uint8 = 0,
    DataType_utf8s,
    DataType_uint16,
    DataType_uint24,
    DataType_uint32,
    DataType_uint40,
    DataType_sint8,
    DataType_SFLOAT,
    DataType_FLOAT,
    DataType_SFLOAT_BIG,
    DataType_FLOAT_BIG,
    DataType_uint32_BIG,
    DataType_uint24_BIG,
    DataType_uint16_BIG,
};

+ (int)sizeOfFormatWithFormatString:(NSString *)format data:(NSData *)data;

+(NSData *)parserObject2Data:(id)object withFormatString:(DataType)type;

+(id)parserData:(NSData*)data withFormatString:(NSString *)type from:(NSInteger)begin;

+(double)parserData:(NSData*)data withFormat:(DataType)type from:(NSInteger)begin;

+(NSData *) dataWithString:(NSString *)sendString;

+(NSString *)stringWithData:(NSData *)data;
//+(int) getBit:(int) byte (int) index);
//int getTwoBit(int byte,int index);

+(NSString *)getDate:(NSData*)data index:(int)index;

+(NSString *)getStringWithUUID:(CBUUID *)uuid;
@end
