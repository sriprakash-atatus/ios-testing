/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddRUM` -> `AtatusRUM`; renamed the `DD` symbol
// prefix to `AT`; rebranded the licence header.

#import <XCTest/XCTest.h>
@import AtatusRUM;

@interface ATRUMMonitor_apiTests : XCTestCase
@end

/*
 * Objc APIs smoke tests - only check if the interface is available to Objc.
 */
@implementation ATRUMMonitor_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"

#if !TARGET_OS_WATCH
- (void)testDDRUMViewAPI {
    ATRUMView *view = [[ATRUMView alloc] initWithName:@"abc" attributes:@{@"foo": @"bar"}];
    XCTAssertEqual(view.name, @"abc");
    XCTAssertNotNil(view.attributes[@"foo"]); // TODO: RUMM-1583 assert with `XCTAssertEqual`
}

- (void)testDDRUMActionAPI {
    ATRUMAction *action = [[ATRUMAction alloc] initWithName:@"abc" attributes:@{@"foo": @"bar"}];
    XCTAssertEqual(action.name, @"abc");
    XCTAssertNotNil(action.attributes[@"foo"]); // TODO: RUMM-1583 assert with `XCTAssertEqual`
}
#endif

- (void)testDDRUMErrorSourceAPI {
    ATRUMErrorSourceSource; ATRUMErrorSourceNetwork; ATRUMErrorSourceWebview; ATRUMErrorSourceConsole; ATRUMErrorSourceCustom;
}

- (void)testDDRUMActionTypeAPI {
    ATRUMActionTypeTap; ATRUMActionTypeScroll; ATRUMActionTypeSwipe; ATRUMActionTypeCustom;
}

- (void)testDDRUMResourceTypeAPI {
    ATRUMResourceTypeImage; ATRUMResourceTypeXhr; ATRUMResourceTypeBeacon; ATRUMResourceTypeCss; ATRUMResourceTypeDocument;
    ATRUMResourceTypeFetch; ATRUMResourceTypeFont; ATRUMResourceTypeJs; ATRUMResourceTypeMedia; ATRUMResourceTypeOther;
    ATRUMResourceTypeNative;
}

- (void)testDDRUMMethodAPI {
    ATRUMMethodPost; ATRUMMethodGet; ATRUMMethodHead; ATRUMMethodPut; ATRUMMethodDelete; ATRUMMethodPatch; ATRUMMethodConnect;
    ATRUMMethodTrace; ATRUMMethodOptions;
}

- (void)testDDRUMFeatureOperationFailureReasonAPI {
    ATRUMFeatureOperationFailureReasonError; ATRUMFeatureOperationFailureReasonAbandoned; ATRUMFeatureOperationFailureReasonOther;
}

- (void)testDDRUMMonitorAPI {
    ATRUMMonitor *monitor = [ATRUMMonitor shared];
    [monitor currentSessionIDWithCompletion:^(NSString * _Nullable sessionID) {}];
    [monitor stopSession];
    [monitor reportAppFullyDisplayed];

    [monitor addViewAttributeForKey:@"key" value: @"value"];
    [monitor addViewAttributes:@{@"string": @"value", @"integer": @1, @"boolean": @true}];
    [monitor removeViewAttributeForKey:@"key"];
    [monitor removeViewAttributesForKeys:@[@"string",@"integer",@"boolean"]];
    [monitor startViewWithKey:@"view" name:@"" attributes:@{}];
    [monitor stopViewWithKey:@"view" attributes:@{}];
    [monitor startViewWithKey:@"" name:nil attributes:@{}];
    [monitor stopViewWithKey:@"" attributes:@{}];
    [monitor addViewLoadingTimeWithOverwrite:YES];

    [monitor addErrorWithMessage:@"" stack:nil source:ATRUMErrorSourceCustom attributes:@{}];
    [monitor addErrorWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:-100 userInfo:nil]
                        source:ATRUMErrorSourceNetwork attributes:@{}];

    [monitor startResourceWithResourceKey:@"" request:[NSURLRequest new] attributes:@{}];
    [monitor startResourceWithResourceKey:@"" url:[NSURL new] attributes:@{}];
    [monitor startResourceWithResourceKey:@"" httpMethod:ATRUMMethodGet urlString:@"" attributes:@{}];
    [monitor addResourceMetricsWithResourceKey:@"" metrics:[NSURLSessionTaskMetrics new] attributes:@{}];
    [monitor stopResourceWithResourceKey:@"" response:[NSURLResponse new] size:nil attributes:@{}];
    [monitor stopResourceWithResourceKey:@"" statusCode:nil kind:ATRUMResourceTypeOther size:nil attributes:@{}];
    [monitor stopResourceWithErrorWithResourceKey:@""
                                                   error:[NSError errorWithDomain:NSURLErrorDomain code:-99 userInfo:nil] response:nil attributes:@{}];
    [monitor stopResourceWithErrorWithResourceKey:@"" message:@"" response:nil attributes:@{}];
    [monitor startActionWithType:ATRUMActionTypeSwipe name:@"" attributes:@{}];
    [monitor stopActionWithType:ATRUMActionTypeSwipe name:nil attributes:@{}];
    [monitor addActionWithType:ATRUMActionTypeTap name:@"" attributes:@{}];
    [monitor addAttributeForKey:@"key" value:@"value"];
    [monitor removeAttributeForKey:@"key"];
    [monitor addAttributes:@{@"string": @"value", @"integer": @1, @"boolean": @true}];
    [monitor removeAttributesForKeys:@[@"string",@"integer",@"boolean"]];
    [monitor addFeatureFlagEvaluationWithName: @"name" value: @"value"];
    ATProfilingOptions * options = [[ATProfilingOptions alloc] initWithSampleRate: 100.0];
    [monitor startOperationWithName:@"test_flow" operationKey:@"operation_1" attributes:@{} options: options];
    [monitor succeedOperationWithName:@"test_flow" operationKey:@"operation_1" attributes:@{}];
    [monitor failOperationWithName:@"test_flow" operationKey:@"operation_1" reason:ATRUMFeatureOperationFailureReasonError attributes:@{}];

    [monitor _internal_sync_addError:[NSError errorWithDomain:NSCocoaErrorDomain code:-100 userInfo:nil]
                              source:ATRUMErrorSourceCustom attributes:@{}];

    [monitor setDebug:YES];
    [monitor setDebug:NO];
}

#pragma clang diagnostic pop

@end
