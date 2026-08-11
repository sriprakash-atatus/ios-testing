/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddTrace` -> `AtatusTrace`; renamed the `DD`
// symbol prefix to `AT`; rebranded the licence header.

#import <XCTest/XCTest.h>
@import AtatusTrace;

@interface ATTrace_apiTests : XCTestCase
@end

/*
 * Objc APIs smoke tests - minimal assertions, mainly check if the interface is available to Objc.
 */
@implementation ATTrace_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
#pragma clang diagnostic ignored "-Wunused-variable"

- (void)testDDTraceAPI {
    ATTraceConfiguration *config = [[ATTraceConfiguration alloc] init];
    [ATTrace enableWith:config];
}

- (void)testDDTraceInstanceNameAPI {
    ATTraceConfiguration *config = [[ATTraceConfiguration alloc] init];
    NSString *instanceName = @"trace-test-instance";
    [ATTrace enableWith:config instanceName:instanceName];
    id<OTTracer> tracer = [ATTracer sharedWithInstanceName:instanceName];
    (void)tracer;
}

- (void)testDDTraceConfigurationAPI {
    ATTraceConfiguration *config = [[ATTraceConfiguration alloc] init];

    XCTAssertEqual(config.sampleRate, 100);
    config.sampleRate = 10;
    XCTAssertEqual(config.sampleRate, 10);

    XCTAssertNil(config.service);
    config.service = @"custom-service";
    XCTAssertNotNil(config.service);

    XCTAssertNil(config.tags);
    config.tags = @{};
    XCTAssertNotNil(config.tags);

    ATTraceFirstPartyHostsTracing *tracing;
    tracing = [[ATTraceFirstPartyHostsTracing alloc] initWithHosts:[NSSet new] sampleRate:20];
    tracing = [[ATTraceFirstPartyHostsTracing alloc] initWithHosts:[NSSet new]];
    tracing = [[ATTraceFirstPartyHostsTracing alloc] initWithHostsWithHeaderTypes:@{}];
    tracing = [[ATTraceFirstPartyHostsTracing alloc] initWithHostsWithHeaderTypes:@{} sampleRate:20];
    ATTraceURLSessionTracking *urlSessionTracking = [[ATTraceURLSessionTracking alloc] initWithFirstPartyHostsTracing:tracing];

    config.bundleWithRumEnabled = NO;
    XCTAssertFalse(config.bundleWithRumEnabled);

    config.networkInfoEnabled = YES;
    XCTAssertTrue(config.networkInfoEnabled);

    XCTAssertNil(config.customEndpoint);
    config.customEndpoint = [NSURL new];
    XCTAssertNotNil(config.customEndpoint);
}

- (void)testDDTracerAPI {
    id<OTSpan> rootSpan = [[ATTracer shared] startRootSpan:@"" tags:NULL startTime:NULL customSampleRate:NULL];
    [rootSpan setActive];
    [[ATTracer shared] startSpan:@""];
    [[ATTracer shared] startSpan:@"" tags:@{}];
    [[ATTracer shared] startSpan:@"" childOf:NULL];
    id<OTSpan> span = [[ATTracer shared] startSpan:@"" childOf:NULL tags:NULL startTime:NULL];
    [span finish];
    [span finishWithTime:NULL];
}

#pragma clang diagnostic pop

@end
