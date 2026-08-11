/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddLogs` -> `AtatusLogs`; renamed the `DD`
// symbol prefix to `AT`; rebranded the licence header.

#import <XCTest/XCTest.h>
@import AtatusLogs;

@interface ATLogs_apiTests : XCTestCase
@end

/*
 * Objc API for smoke tests - minimal assertions, mainly check if the interface is available to Objc.
 */
@implementation ATLogs_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
#pragma clang diagnostic ignored "-Wunused-variable"

- (void)testDDLogsAPI {
    ATLogsConfiguration *config = [[ATLogsConfiguration alloc] init];
    [ATLogs enableWith:config];

    [ATLogs addAttributeForKey:@"key1" value:@"value"];
    [ATLogs addAttributeForKey:@"key2" value:@1];
    [ATLogs addAttributeForKey:@"key3" value:@YES];
    [ATLogs addAttributeForKey:@"key4" value:@[@"array"]];
    [ATLogs addAttributeForKey:@"key5" value:@{@"key": @"value"}];

    [ATLogs removeAttributeForKey:@"key1"];
    [ATLogs removeAttributeForKey:@"keyNotAdded"];
}

- (void)testDDLogsInstanceNameAPI {
    NSString *instanceName = @"logs-test-instance";
    ATLogsConfiguration *config = [[ATLogsConfiguration alloc] init];
    [ATLogs enableWith:config instanceName:instanceName];

    [ATLogs addAttributeForKey:@"key1" value:@"value" instanceName:instanceName];
    [ATLogs removeAttributeForKey:@"key1" instanceName:instanceName];
}

- (void)testDDLoggerInstanceNameAPI {
    NSString *instanceName = @"logger-test-instance";
    ATLoggerConfiguration *config = [[ATLoggerConfiguration alloc] init];
    ATLogger *logger = [ATLogger createWith:config instanceName:instanceName];
    [logger debug:@"debug"];
}

- (void)testDDLogsConfigurationAPI {
    ATLogsConfiguration *config = [[ATLogsConfiguration alloc] initWithCustomEndpoint:nil];

    XCTAssertNil(config.customEndpoint);
    config.customEndpoint = [NSURL URLWithString:@"custom-endpoint"];
    XCTAssertNotNil(config.customEndpoint);

    [config setEventMapper:^ATLogEvent * (ATLogEvent* logEvent) {
        logEvent.message = @"log message";
        return logEvent;
    }];
}

- (void)testDDLoggerAPI {
    ATLoggerConfiguration *config = [[ATLoggerConfiguration alloc] init];

    ATLogger* logger = [ATLogger createWith:config];
    [logger addAttributeForKey:@"key" value:@"value"];
    [logger removeAttributeForKey:@"key"];
    [logger addTagWithKey:@"key" value:@"value"];
    [logger removeTagWithKey:@"key"];
    [logger addWithTag:@"foo"];
    [logger removeWithTag:@"foo"];

    [logger debug:@"debug"];
    [logger debug:@"debug" attributes:@{}];
    [logger debug:@"debug" error: [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil] attributes:@{}];
    [logger info:@"info"];
    [logger info:@"info" attributes:@{}];
    [logger info:@"info" error: [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil] attributes:@{}];
    [logger notice:@"notice"];
    [logger notice:@"notice" attributes:@{}];
    [logger notice:@"notice" error: [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil] attributes:@{}];
    [logger warn:@"warn"];
    [logger warn:@"warn" attributes:@{}];
    [logger warn:@"warn" error: [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil] attributes:@{}];
    [logger error:@"error"];
    [logger error:@"error" attributes:@{}];
    [logger error:@"error" error: [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil] attributes:@{}];
    [logger critical:@"critical"];
    [logger critical:@"critical" attributes:@{}];
    [logger critical:@"critical" error: [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil] attributes:@{}];
}

- (void)testDDLoggerConfigurationAPI {
    ATLoggerConfiguration *config = [[ATLoggerConfiguration alloc]
                                     initWithService:nil
                                     name:nil
                                     networkInfoEnabled:NO
                                     bundleWithRumEnabled:NO
                                     bundleWithTraceEnabled:NO
                                     remoteSampleRate:0
                                     remoteLogThreshold:ATLogLevelDebug
                                     printLogsToConsole:NO];

    XCTAssertNil(config.service);
    config.service = @"service";
    XCTAssertNotNil(config.service);

    XCTAssertNil(config.name);
    config.name = @"name";
    XCTAssertNotNil(config.name);

    XCTAssertFalse(config.networkInfoEnabled);
    config.networkInfoEnabled = YES;
    XCTAssertTrue(config.networkInfoEnabled);

    XCTAssertFalse(config.bundleWithRumEnabled);
    config.bundleWithRumEnabled = YES;
    XCTAssertTrue(config.bundleWithRumEnabled);

    XCTAssertFalse(config.bundleWithTraceEnabled);
    config.bundleWithTraceEnabled = YES;
    XCTAssertTrue(config.bundleWithTraceEnabled);

    XCTAssertEqual(config.remoteSampleRate, 0);
    config.remoteSampleRate = 100;
    XCTAssertEqual(config.remoteSampleRate, 100);

    XCTAssertEqual(config.remoteLogThreshold, ATLogLevelDebug);
    config.remoteLogThreshold = ATLogLevelError;
    XCTAssertEqual(config.remoteLogThreshold, ATLogLevelError);

    XCTAssertFalse(config.printLogsToConsole);
    config.printLogsToConsole = YES;
    XCTAssertTrue(config.printLogsToConsole);
}


#pragma clang diagnostic pop

@end

