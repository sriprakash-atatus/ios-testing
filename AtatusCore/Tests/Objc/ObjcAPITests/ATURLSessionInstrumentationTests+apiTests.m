/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddTrace` ->
// `AtatusTrace`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#import <XCTest/XCTest.h>
#include <sys/wait.h>
@import AtatusCore;
@import AtatusTrace;

#import <Foundation/Foundation.h>

@interface MockDelegate : NSObject <NSURLSessionDataDelegate>
@end

@implementation MockDelegate
@end

@interface ATURLSessionInstrumentationTests_apiTests : XCTestCase
@end

@implementation ATURLSessionInstrumentationTests_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"

- (void)setUp {
    [super setUp];

    ATConfiguration *configuration = [[ATConfiguration alloc] initWithClientToken:@"abc" env:@"def"];
    [ATAtatus initializeWithConfiguration:configuration trackingConsent:[ATTrackingConsent notGranted]];

    ATTraceConfiguration *config = [[ATTraceConfiguration alloc] init];
    ATTraceFirstPartyHostsTracing *tracing = [[ATTraceFirstPartyHostsTracing alloc] initWithHosts:[NSSet new] sampleRate:20];
    ATTraceURLSessionTracking *urlSessionTracking = [[ATTraceURLSessionTracking alloc] initWithFirstPartyHostsTracing:tracing];
    [config setURLSessionTracking:urlSessionTracking];
    [ATTrace enableWith:config];
}

- (void)tearDown {
    [super tearDown];

    [ATAtatus clearAllData];
    [ATAtatus flushAndDeinitialize];
}

- (void)testWorkflow {
    XCTestExpectation *expectation = [self expectationWithDescription:@"task completed"];
    ATURLSessionInstrumentationConfiguration *config = [[ATURLSessionInstrumentationConfiguration alloc] initWithDelegateClass:[MockDelegate class]];
    [ATURLSessionInstrumentation enableDurationBreakdownWith:config];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:[MockDelegate new] delegateQueue:nil];
    NSURLSessionTask *task = [session dataTaskWithURL:[NSURL URLWithString:@"https://www.atatus.com/"]
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [expectation fulfill];
    }];
    [task resume];

    [self waitForExpectationsWithTimeout:10 handler:nil];

    [ATURLSessionInstrumentation disableWithDelegateClass:[MockDelegate class]];
}

- (void)testURLSessionInstrumentationInstanceNameAPI {
    ATURLSessionInstrumentationConfiguration *config = [[ATURLSessionInstrumentationConfiguration alloc] initWithDelegateClass:[MockDelegate class]];
    NSString *instanceName = @"urlsession-test-instance";
    [ATURLSessionInstrumentation enableDurationBreakdownWith:config instanceName:instanceName];
    [ATURLSessionInstrumentation disableWithDelegateClass:[MockDelegate class] instanceName:instanceName];
}

#pragma clang diagnostic pop

@end
