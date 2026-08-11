/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#import <XCTest/XCTest.h>
@import AtatusCore;
@import AtatusInternal;

@interface ATCrossPlatformExtension_apiTests : XCTestCase
@end

/*
 * Objc APIs smoke tests - only check if the interface is available to Objc.
 */
@implementation ATCrossPlatformExtension_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"

- (void)testDDContextSharingExtensionAPI {
    [ATCrossPlatformExtension subscribeToSharedContext:^(ATSharedContext * _Nullable context) {
        // Just check API availability in Objective-C
    }];

    [ATCrossPlatformExtension unsubscribeFromSharedContext];
}

#pragma clang diagnostic pop

@end
