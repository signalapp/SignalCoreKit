//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const SCKExceptionWrapperErrorDomain;
typedef NS_ERROR_ENUM(SCKExceptionWrapperErrorDomain, SCKExceptionWrapperError) {
    SCKExceptionWrapperErrorThrown = 900
};

extern NSErrorUserInfoKey const SCKExceptionWrapperUnderlyingExceptionKey;

NSError *SCKExceptionWrapperErrorMake(NSException *exception);

/// Naming conventions:
///
/// Every objc method that can throw an exception should be prefixed with `try_`.
/// e.g. `try_foo` and `try_fooWithBar:bar`
///
/// Every objc method that *calls* an uncaught `try_` method can throw an exception,
/// so transitively, it should be a `try_method`
///
/// WRONG!:
///
///     -(void)bar
///     {
///         [foo try_foo];
///     }
///
/// RIGHT!:
///
///     -(void)try_bar
///     {
///         [foo try_foo];
///     }
///
/// WRONG!:
///
///     -(void)try_bar
///     {
///         @try {
///             [foo try_foo];
///         } @catch(NSException *exception) {
///             // all exceptions are caught,
///             // so bar doesn't throw.
///             [self doSomethingElse];
///         }
///     }
///
/// RIGHT!:
///
///     -(void)bar
///     {
///         @try {
///             [foo try_foo];
///         } @catch(NSException *exception) {
///             // all exceptions are caught,
///             // so bar doesn't throw.
///             [self doSomethingElse];
///         }
///     }
///
/// Since initializers must start with the word `init`, an initializer which throws is labeled
/// somewhat awkwardly as: `init_try_foo` or `init_try_withFoo:`
///
///
/// Any method that can throw an objc exception must not be called from swift, so must be marked
/// as NS_SWIFT_UNAVAILABLE("some helpful comment or alternative"). When appropriate, provide a
/// Swift safe wrapper using SCKExceptionWrapper.
///
///
///     -(BOOL)barAndReturnError:(NSError **)outError
///     {
///         return [SCKExceptionWrapper tryBlock:^{ [self try_bar]; }
///                                        error:outError];
///     }
///
///     -(void)try_bar
///     {
///         [foo try_foo];
///     }

NS_SWIFT_UNAVAILABLE("throws objc exceptions")
@interface SCKExceptionWrapper: NSObject

+ (BOOL)tryBlock:(void (^)(void))block error:(NSError **)outError;

@end

void SCKRaiseIfExceptionWrapperError(NSError *_Nullable error) NS_SWIFT_UNAVAILABLE("throws objc exceptions");

NS_ASSUME_NONNULL_END
