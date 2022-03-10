//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for SignalCoreKit.
FOUNDATION_EXPORT double SignalCoreKitVersionNumber;

//! Project version string for SignalCoreKit.
FOUNDATION_EXPORT const unsigned char SignalCoreKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SignalCoreKit/PublicHeader.h>
#import <SignalCoreKit/Cryptography.h>
#import <SignalCoreKit/SCKError.h>
#import <SignalCoreKit/UnfairLock.h>

#ifdef __OBJC__
    #define OWSLocalizedString(key, comment) \
        [[NSBundle mainBundle].app localizedStringForKey:(key) value:@"" table:nil]
#endif
