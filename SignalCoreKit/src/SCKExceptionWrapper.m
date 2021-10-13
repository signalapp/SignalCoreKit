//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "SCKExceptionWrapper.h"

NS_ASSUME_NONNULL_BEGIN

NSErrorDomain const SCKExceptionWrapperErrorDomain = @"SignalCoreKit.SCKExceptionWrapper";
NSErrorUserInfoKey const SCKExceptionWrapperUnderlyingExceptionKey = @"SCKExceptionWrapperUnderlyingException";

NSError *SCKExceptionWrapperErrorMake(NSException *exception)
{
    return [NSError errorWithDomain:SCKExceptionWrapperErrorDomain
                               code:SCKExceptionWrapperErrorThrown
                           userInfo:@{ SCKExceptionWrapperUnderlyingExceptionKey : exception }];
}

@implementation SCKExceptionWrapper

+ (BOOL)tryBlock:(void (^)(void))block error:(NSError **)outError
{
    OWSAssertDebug(outError);
    @try {
        block();
        return YES;
    } @catch (NSException *exception) {
        if (outError) {
            *outError = SCKExceptionWrapperErrorMake(exception);
        }
        return NO;
    }
}

+ (void)__exceptionLoggerWithLabel:(NSString *)label
                              file:(const char *)file
                          function:(const char *)function
                              line:(NSInteger)line
                             block:(void (NS_NOESCAPE ^)(void))tryBlock
                        errorBlock:(void (NS_NOESCAPE ^_Nullable)(void))errorBlock
{
    @try {
        tryBlock();
    } @catch (NSException *exception) {
        // We format the filename & line number in a format compatible
        // with XCode's "Open Quickly..." feature.
        NSString *filename = [[NSString stringWithFormat:@"%s", file] lastPathComponent];
        NSString *locationString = [NSString stringWithFormat:@"%@:%ld %s", filename, line, function];

        OWSLogError(@"Exception (%@): %@.", locationString, label);
        OWSLogError(@"Exception stack: %@.", exception.callStackSymbols);
        OWSFailDebug(@"Exception: %@ of type: %@ with reason: %@, user info: %@.",
                     exception.description,
                     exception.name,
                     exception.reason,
                     exception.userInfo);
        if (errorBlock) {
            errorBlock();
        }
        OWSLogFlush();
        @throw exception;
    }
}

@end

void SCKRaiseIfExceptionWrapperError(NSError *_Nullable error)
{
    if (error && [error.domain isEqualToString:SCKExceptionWrapperErrorDomain]
        && error.code == SCKExceptionWrapperErrorThrown) {
        NSException *_Nullable exception = error.userInfo[SCKExceptionWrapperUnderlyingExceptionKey];
        OWSCAssert(exception);
        @throw exception;
    }
}

NS_ASSUME_NONNULL_END
