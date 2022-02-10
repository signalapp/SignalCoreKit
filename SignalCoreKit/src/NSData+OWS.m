//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "NSData+OWS.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSData (OWS)

+ (NSData *)join:(NSArray<NSData *> *)datas
{
    OWSAssert(datas);

    NSMutableData *result = [NSMutableData new];
    for (NSData *data in datas) {
        [result appendData:data];
    }
    return [result copy];
}

- (NSData *)dataByAppendingData:(NSData *)data
{
    NSMutableData *result = [self mutableCopy];
    [result appendData:data];
    return [result copy];
}

#pragma mark - Hex

- (NSString *)hexadecimalString
{
    /* Returns hexadecimal string of NSData. Empty string if data is empty. */
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
    if (!dataBuffer) {
        return @"";
    }

    NSUInteger dataLength = [self length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];

    for (NSUInteger i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }
    return [hexString copy];
}

+ (nullable NSData *)dataFromHexString:(NSString *)hexString {
    NSMutableData *data = [NSMutableData new];
    
    if (hexString.length % 2 != 0) {
        OWSFailDebug(@"Hexadecimal string has unexpected length: %@ (%lu)", hexString, (unsigned long)hexString.length);
        return nil;
    }
    for (NSUInteger i = 0; i + 2 <= hexString.length; i += 2) {
        NSString *_Nullable byteString = [hexString substringWithRange:NSMakeRange(i, 2)];
        if (!byteString) {
            OWSFailDebug(@"Couldn't slice hexadecimal string.");
            return nil;
        }
        unsigned byteValue;
        if (![[NSScanner scannerWithString:byteString] scanHexInt:&byteValue]) {
            OWSFailDebug(@"Couldn't parse hex byte: %@.", byteString);
            return nil;
        }
        if (byteValue > 0xff) {
            OWSFailDebug(@"Invalid hex byte: %@ (%d).", byteString, byteValue);
            return nil;
        }
        uint8_t byte = (uint8_t)(0xff & byteValue);
        [data appendBytes:&byte length:1];
    }
    return [data copy];
}

#pragma mark - Base64

+ (nullable NSData *)dataFromBase64StringNoPadding:(NSString *)aString
{
    int padding = aString.length % 4;

    NSMutableString *strResult = [aString mutableCopy];
    if (padding != 0) {
        int charsToAdd = 4 - padding;
        for (int i = 0; i < charsToAdd; i++) {
            [strResult appendString:@"="];
        }
    }
    return [self dataFromBase64String:strResult];
}

//
// dataFromBase64String:
//
// Creates an NSData object containing the base64 decoded representation of
// the base64 string 'aString'
//
// Parameters:
//    aString - the base64 string to decode
//
// returns the NSData representation of the base64 string
//

+ (nullable NSData *)dataFromBase64String:(NSString *)aString
{
    return [[NSData alloc] initWithBase64EncodedString:aString options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

//
// base64EncodedString
//
// Creates an NSString object that contains the base 64 encoding of the
// receiver's data. Lines are broken at 64 characters long.
//
// returns an NSString being the base 64 representation of the
//    receiver.
//
- (NSString *)base64EncodedString
{
    return [self base64EncodedStringWithOptions:0];
}

#pragma mark -

- (BOOL)ows_constantTimeIsEqualToData:(NSData *)other
{
    volatile UInt8 isEqual = 0;
    
    if (self.length != other.length) {
        return NO;
    }
    
    UInt8 *leftBytes = (UInt8 *)self.bytes;
    UInt8 *rightBytes = (UInt8 *)other.bytes;
    for (int i = 0; i < self.length; i++) {
        // rather than returning as soon as we find a discrepancy, we compare the rest of
        // the byte stream to maintain a constant time comparison
        isEqual |= leftBytes[i] ^ rightBytes[i];
    }
    
    return isEqual == 0;
}

@end

NS_ASSUME_NONNULL_END
