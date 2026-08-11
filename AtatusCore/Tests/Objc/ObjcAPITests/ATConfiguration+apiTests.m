/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`,
// `ddCrashReporting` -> `AtatusCrashReporting`; renamed the `DD` symbol prefix to `AT`; rebranded the
// licence header.

#import <XCTest/XCTest.h>
@import AtatusCore;
@import AtatusCrashReporting;

// MARK: - ATDataEncryption

@interface CustomDDDataEncryption: NSObject <ATDataEncryption>
@end

@implementation CustomDDDataEncryption

- (NSData * _Nullable)decryptWithData:(NSData * _Nonnull)data error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return data;
}

- (NSData * _Nullable)encryptWithData:(NSData * _Nonnull)data error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return data;
}

@end

// MARK: - Tests

@interface ATConfiguration_apiTests : XCTestCase
@end

/*
 * Objc APIs smoke tests - only check if the interface is available to Objc.
 */
@implementation ATConfiguration_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"

- (void)testDDSiteAPI {
    [ATSite us1];
    [ATSite us3];
    [ATSite us5];
    [ATSite eu1];
    [ATSite ap1];
    [ATSite ap2];
    [ATSite uk1];
    [ATSite us1_fed];
    [ATSite us2_fed];
}

- (void)testDDBatchSizeAPI {
    ATBatchSizeSmall; ATBatchSizeMedium; ATBatchSizeLarge;
}

- (void)testDDUploadFrequencyAPI {
    ATUploadFrequencyRare; ATUploadFrequencyAverage; ATUploadFrequencyFrequent;
}

- (void)testDDConfigurationBuilderAPI {
    ATConfiguration *configuration = [[ATConfiguration alloc] initWithClientToken:@"abc" env:@"def"];

    configuration.site = [ATSite us1];
    configuration.service = @"";
    configuration.bundle = [NSBundle mainBundle];
    configuration.batchSize = ATBatchSizeMedium;
    configuration.uploadFrequency = ATUploadFrequencyAverage;
    configuration.additionalConfiguration = @{@"additional": @"config"};
    [configuration setEncryption:[CustomDDDataEncryption new]];
    configuration.backgroundTasksEnabled = true;
}

- (void)testAtatusCrashReporterAPI {
    [ATCrashReporter enable];
}

#pragma clang diagnostic pop

@end
