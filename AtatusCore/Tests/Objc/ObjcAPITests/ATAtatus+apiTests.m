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

@interface ATAtatus_apiTests : XCTestCase
@end

/*
 * Objc APIs smoke tests - only check if the interface is available to Objc.
 */
@implementation ATAtatus_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"

- (void)testDDTrackingConsentAPI {
    [ATTrackingConsent granted];
    [ATTrackingConsent notGranted];
    [ATTrackingConsent pending];
}

- (void)testDDAtatus {
    ATConfiguration *configuration = [[ATConfiguration alloc] initWithClientToken:@"abc" env:@"def"];

    [ATAtatus initializeWithConfiguration:configuration trackingConsent:[ATTrackingConsent notGranted]];

    [ATAtatus isInitialized];

    ATCoreLoggerLevel verbosity = [ATAtatus verbosityLevel];
    [ATAtatus setVerbosityLevel:verbosity];

    [ATAtatus setUserInfoWithUserId:@"" name:@"" email:@"" extraInfo:@{}];
    [ATAtatus addUserExtraInfo:@{}];
    [ATAtatus setTrackingConsentWithConsent:[ATTrackingConsent notGranted]];

    [ATAtatus clearAllData];
    [ATAtatus stopInstance];
}

- (void)testDDAtatusInstanceNameAPI {
    NSString *instanceName = @"test-instance";
    ATConfiguration *configuration = [[ATConfiguration alloc] initWithClientToken:@"abc" env:@"def"];

    [ATAtatus initializeWithConfiguration:configuration trackingConsent:[ATTrackingConsent notGranted] instanceName:instanceName];

    XCTAssertTrue([ATAtatus isInitializedWithInstanceName:instanceName]);

    [ATAtatus setUserInfoWithUserId:@"user-id" instanceName:instanceName name:@"name" email:@"email" extraInfo:@{}];
    [ATAtatus addUserExtraInfo:@{} instanceName:instanceName];
    [ATAtatus clearUserInfoWithInstanceName:instanceName];

    [ATAtatus setAccountInfoWithAccountId:@"account-id" instanceName:instanceName name:@"name" extraInfo:@{}];
    [ATAtatus addAccountExtraInfo:@{} instanceName:instanceName];
    [ATAtatus clearAccountInfoWithInstanceName:instanceName];

    [ATAtatus setTrackingConsentWithConsent:[ATTrackingConsent notGranted] instanceName:instanceName];
    [ATAtatus clearAllDataWithInstanceName:instanceName];
    [ATAtatus stopInstanceWithInstanceName:instanceName];
}

#pragma clang diagnostic pop

@end
