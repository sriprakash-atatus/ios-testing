/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddWebViewTracking` -> `AtatusWebViewTracking`;
// renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#import <XCTest/XCTest.h>

#if TARGET_OS_IOS || TARGET_OS_VISION


@import AtatusWebViewTracking;
@import WebKit;

@interface WebViewMock: WKWebView
@end

@implementation WebViewMock
@end

// MARK: - ATWebViewTracking tests

@interface ATWebViewTracking_apiTests : XCTestCase
@end

/*
 * `WebViewTracking` APIs smoke tests - minimal assertions, mainly check if the interface is available to Objc.
 */
@implementation ATWebViewTracking_apiTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"

- (void)testDDWebViewTrackingAPI {
    WebViewMock *webView = [WebViewMock new];
    [ATWebViewTracking enableWithWebView:webView
                                   hosts:[NSSet<NSString*> setWithArray:@[@"host1.com", @"host2.com"]]
                          logsSampleRate:100.0
    ];
    [ATWebViewTracking disableWithWebView:webView];
}

- (void)testDDWebViewTrackingInstanceNameAPI {
    WebViewMock *webView = [WebViewMock new];
    NSString *instanceName = @"webview-test-instance";
    [ATWebViewTracking enableWithWebView:webView
                            instanceName:instanceName
                                   hosts:[NSSet<NSString*> setWithArray:@[@"host1.com"]]
                          logsSampleRate:100.0
    ];
    [ATWebViewTracking disableWithWebView:webView];
}

#pragma clang diagnostic pop

@end

#endif
