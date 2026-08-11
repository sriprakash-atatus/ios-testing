/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#import <XCTest/XCTest.h>
@import AtatusRUM;
@import AtatusInternal;

// MARK: - ATNetworkSettledResourcePredicate

@interface CustomDDNetworkSettledResourcePredicate: NSObject
@end

@interface CustomDDNetworkSettledResourcePredicate () <ATNetworkSettledResourcePredicate>
@end

@implementation CustomDDNetworkSettledResourcePredicate
- (BOOL)isInitialResourceFrom:(ATTNSResourceParams * _Nonnull)resourceParams { return YES; }
@end

// MARK: - ATNextViewActionPredicate

@interface CustomDDNextViewActionPredicate: NSObject
@end

@interface CustomDDNextViewActionPredicate () <ATNextViewActionPredicate>
@end

@implementation CustomDDNextViewActionPredicate
- (BOOL)isLastActionFrom:(ATINVActionParams * _Nonnull)actionParams { return YES; }
@end

#if !TARGET_OS_WATCH

// MARK: - ATUIKitRUMViewsPredicate

@interface CustomDDUIKitRUMViewsPredicate: NSObject
@end

@interface CustomDDUIKitRUMViewsPredicate () <ATUIKitRUMViewsPredicate>
@end

@implementation CustomDDUIKitRUMViewsPredicate
- (ATRUMView * _Nullable)rumViewFor:(UIViewController * _Nonnull)viewController { return nil; }
@end

// MARK: - ATUIKitRUMActionsPredicate

@interface CustomDDUIKitRUMActionsPredicate: NSObject
@end

@interface CustomDDUIKitRUMActionsPredicate () <ATUIKitRUMActionsPredicate>
@end

@implementation CustomDDUIKitRUMActionsPredicate
- (ATRUMAction * _Nullable)rumActionWithTargetView:(UIView * _Nonnull)targetView { return nil; }
- (ATRUMAction * _Nullable)rumActionWithPress:(enum UIPressType)type targetView:(UIView * _Nonnull)targetView { return nil; }

@end

#endif

// MARK: - ATRUM tests

@interface ATRUM_apiTests : XCTestCase
@end

/*
 * Objc APIs smoke tests - minimal assertions, mainly check if the interface is available to Objc.
 */
@implementation ATRUM_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"

- (void)testDDRUMAPI {
    ATRUMConfiguration *config = [[ATRUMConfiguration alloc] initWithApplicationID:@"app-id"];
    [ATRUM enableWith:config];
}

- (void)testDDRUMInstanceNameAPI {
    ATRUMConfiguration *config = [[ATRUMConfiguration alloc] initWithApplicationID:@"app-id"];
    NSString *instanceName = @"rum-test-instance";
    [ATRUM enableWith:config instanceName:instanceName];
    ATRUMMonitor *monitor = [ATRUMMonitor sharedWithInstanceName:instanceName];
    (void)monitor;
}

- (void)testDDRUMConfigurationAPI {
    ATRUMConfiguration *config = [[ATRUMConfiguration alloc] initWithApplicationID:@"app-id"];
    XCTAssertEqual(config.applicationID, @"app-id");

    XCTAssertEqual(config.sessionSampleRate, 100);
    config.sessionSampleRate = 10;
    XCTAssertEqual(config.sessionSampleRate, 10);

    XCTAssertEqual(config.telemetrySampleRate, 20);
    config.telemetrySampleRate = 30;
    XCTAssertEqual(config.telemetrySampleRate, 30);

    XCTAssertNotNil(config.networkSettledResourcePredicate);
    CustomDDNetworkSettledResourcePredicate *tnsPredicate = [CustomDDNetworkSettledResourcePredicate new];
    config.networkSettledResourcePredicate = tnsPredicate;
    XCTAssertIdentical(config.networkSettledResourcePredicate, tnsPredicate);

    ATTimeBasedTNSResourcePredicate *defaultTNSPredicate = [[ATTimeBasedTNSResourcePredicate alloc] initWithThreshold:0.2];
    config.networkSettledResourcePredicate = defaultTNSPredicate;
    XCTAssertNotNil(config.networkSettledResourcePredicate);

    XCTAssertNotNil(config.nextViewActionPredicate);
    CustomDDNextViewActionPredicate *invPredicate = [CustomDDNextViewActionPredicate new];
    config.nextViewActionPredicate = invPredicate;
    XCTAssertIdentical(config.nextViewActionPredicate, invPredicate);

    ATTimeBasedINVActionPredicate *defaultINVPredicate = [[ATTimeBasedINVActionPredicate alloc] initWithMaxTimeToNextView:5.0];
    config.nextViewActionPredicate = defaultINVPredicate;
    XCTAssertNotNil(config.nextViewActionPredicate);

#if !TARGET_OS_WATCH
    XCTAssertNil(config.uiKitViewsPredicate);
    CustomDDUIKitRUMViewsPredicate *viewsPredicate = [CustomDDUIKitRUMViewsPredicate new];
    config.uiKitViewsPredicate = viewsPredicate;
    XCTAssertIdentical(config.uiKitViewsPredicate, viewsPredicate);

    XCTAssertNil(config.uiKitActionsPredicate);
    CustomDDUIKitRUMActionsPredicate *actionsPredicate = [CustomDDUIKitRUMActionsPredicate new];
    config.uiKitActionsPredicate = actionsPredicate;
    XCTAssertIdentical(config.uiKitActionsPredicate, actionsPredicate);

    XCTAssertNil(config.swiftUIViewsPredicate);
    ATDefaultSwiftUIRUMViewsPredicate *swiftUIViewsPredicate = [ATDefaultSwiftUIRUMViewsPredicate new];
    config.swiftUIViewsPredicate = swiftUIViewsPredicate;
    XCTAssertIdentical(config.swiftUIViewsPredicate, swiftUIViewsPredicate);

    XCTAssertNil(config.swiftUIActionsPredicate);
    ATDefaultSwiftUIRUMActionsPredicate *swiftUIActionsPredicate = [[ATDefaultSwiftUIRUMActionsPredicate alloc] initWithIsLegacyDetectionEnabled:YES];
    config.swiftUIActionsPredicate = swiftUIActionsPredicate;
    XCTAssertIdentical(config.swiftUIActionsPredicate, swiftUIActionsPredicate);
#endif

    ATRUMURLSessionTracking *urlSessionTracking = [ATRUMURLSessionTracking new];
    ATRUMFirstPartyHostsTracing *tracing;
    tracing = [[ATRUMFirstPartyHostsTracing alloc] initWithHosts:[NSSet new] sampleRate:20];
    tracing = [[ATRUMFirstPartyHostsTracing alloc] initWithHosts:[NSSet new]];
    tracing = [[ATRUMFirstPartyHostsTracing alloc] initWithHostsWithHeaderTypes:@{}];
    tracing = [[ATRUMFirstPartyHostsTracing alloc] initWithHostsWithHeaderTypes:@{} sampleRate:20];
    [urlSessionTracking setFirstPartyHostsTracing:tracing];
    [urlSessionTracking setResourceAttributesProvider:^NSDictionary<NSString *,id> * _Nullable(NSURLRequest * _Nonnull request,
                                                                                                NSURLResponse * _Nullable response,
                                                                                                NSData * _Nullable data,
                                                                                                NSError * _Nullable error) {
        return @{};
    }];

    XCTAssertTrue(config.trackFrustrations);
    config.trackFrustrations = NO;
    XCTAssertFalse(config.trackFrustrations);

    XCTAssertFalse(config.trackBackgroundEvents);
    config.trackBackgroundEvents = YES;
    XCTAssertTrue(config.trackBackgroundEvents);

    XCTAssertEqual(config.longTaskThreshold, 0.1);
    config.longTaskThreshold = 1;
    XCTAssertEqual(config.longTaskThreshold, 1);

    XCTAssertEqual(config.appHangThreshold, 0);
    config.appHangThreshold = 1;
    XCTAssertEqual(config.appHangThreshold, 1);

    XCTAssertEqual(config.vitalsUpdateFrequency, ATRUMVitalsFrequencyAverage);
    config.vitalsUpdateFrequency = ATRUMVitalsFrequencyFrequent;
    XCTAssertEqual(config.vitalsUpdateFrequency, ATRUMVitalsFrequencyFrequent);
    config.vitalsUpdateFrequency = ATRUMVitalsFrequencyNever;
    XCTAssertEqual(config.vitalsUpdateFrequency, ATRUMVitalsFrequencyNever);

    [config setViewEventMapper:^ATRUMViewEvent * _Nonnull(ATRUMViewEvent * _Nonnull viewEvent) {
        viewEvent.view.url = @"";
        return viewEvent;
    }];
    [config setResourceEventMapper:^ATRUMResourceEvent * _Nullable(ATRUMResourceEvent * _Nonnull resourceEvent) {
        resourceEvent.resource.url = @"";
        return resourceEvent;
    }];
    [config setActionEventMapper:^ATRUMActionEvent * _Nullable(ATRUMActionEvent * _Nonnull actionEvent) {
        return nil;
    }];
    [config setErrorEventMapper:^ATRUMErrorEvent * _Nullable(ATRUMErrorEvent * _Nonnull errorEvent) {
        return nil;
    }];
    [config setLongTaskEventMapper:^ATRUMLongTaskEvent * _Nullable(ATRUMLongTaskEvent * _Nonnull longTaskEvent) {
        return nil;
    }];

    XCTAssertNil(config.onSessionStart);
    config.onSessionStart = ^(NSString * _Nonnull uuid, BOOL discarded) {};
    XCTAssertNotNil(config.onSessionStart);

    XCTAssertNil(config.customEndpoint);
    config.customEndpoint = [NSURL new];
    XCTAssertNotNil(config.customEndpoint);

    XCTAssertTrue(config.trackAnonymousUser);
    config.trackAnonymousUser = NO;
    XCTAssertFalse(config.trackAnonymousUser);

#if !TARGET_OS_WATCH
    XCTAssertTrue(config.trackMemoryWarnings);
    config.trackMemoryWarnings = NO;
    XCTAssertFalse(config.trackMemoryWarnings);

    XCTAssertFalse(config.collectAccessibility);
    config.collectAccessibility = YES;
    XCTAssertTrue(config.collectAccessibility);
#endif
}

#pragma clang diagnostic pop

@end
