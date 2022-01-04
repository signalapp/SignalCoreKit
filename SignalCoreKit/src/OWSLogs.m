//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSLogs.h"

NS_ASSUME_NONNULL_BEGIN

@implementation OWSLogger

+ (void)verbose:(NSString *)logString
{
    DDLogVerbose(@"💙 %@", logString);
}

+ (void)debug:(NSString *)logString
{
    DDLogDebug(@"💚 %@", logString);
}

+ (void)info:(NSString *)logString
{
    DDLogInfo(@"💛 %@", logString);
    if (self.aggressiveFlushing) {
        [self flush];
    }
}

+ (void)warn:(NSString *)logString
{
    DDLogWarn(@"🧡 %@", logString);
    if (self.aggressiveFlushing) {
        [self flush];
    }
}

+ (void)error:(NSString *)logString
{
    DDLogError(@"❤️ %@", logString);
    if (self.aggressiveFlushing) {
        [self flush];
    }
}

+ (void)flush
{
    OWSLogFlush();
}

static BOOL aggressiveLogFlushingEnabled = NO;

+ (BOOL)aggressiveFlushing
{
    @synchronized (self) {
        return aggressiveLogFlushingEnabled;
    }
}

+ (void)setAggressiveFlushing:(BOOL)isEnabled
{
    @synchronized (self) {
        aggressiveLogFlushingEnabled = isEnabled;
    }
}

@end

NS_ASSUME_NONNULL_END
