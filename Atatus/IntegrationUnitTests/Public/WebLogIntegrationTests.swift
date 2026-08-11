/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddLogs`
// -> `AtatusLogs`, `ddRUM` -> `AtatusRUM`, `ddWebViewTracking` -> `AtatusWebViewTracking`;
// renamed `dd*` types to `Atatus*`; renamed the `ddsource` / `ddtags` query parameters to
// `atatus_source` / `atatustags`; rebranded the licence header.

import XCTest

#if !os(tvOS) && !os(watchOS)

import AtatusInternal
import TestUtilities
import WebKit

@testable import AtatusLogs
@testable import AtatusRUM
@testable import AtatusWebViewTracking

@MainActor
class WebLogIntegrationTests: XCTestCase {
    private var core: AtatusCoreProxy! // swiftlint:disable:this implicitly_unwrapped_optional
    private var controller: WKUserContentControllerMock! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUpWithError() throws {
        core = AtatusCoreProxy(
            context: .mockWith(
                env: "test",
                version: "1.1.1",
                serverTimeOffset: 123
            )
        )

        let config = WKWebViewConfiguration()
        controller = WKUserContentControllerMock()
        config.userContentController = controller
        let webView = WKWebView(frame: .zero, configuration: config)

        try WebViewTracking.enableOrThrow(
            tracking: webView,
            hosts: [],
            hostsSanitizer: HostsSanitizer(),
            logsSampleRate: 100,
            in: core
        )
    }

    override func tearDownWithError() throws {
        try core.flushAndTearDown()
        core = nil
        controller = nil
    }

    func testWebLogIntegration() throws {
        // Given
        Logs.enable(in: core)

        let body = """
        {
            "eventType": "log",
            "event": {
                "date" : \(1_635_932_927_012),
                "status": "debug",
                "message": "message",
                "session_id": "0110cab4-7471-480e-aa4e-7ce039ced355",
                "view": {
                    "referrer": "",
                    "url": "https://atatus.dev/browser-sdk-test-playground"
                }
            }
        }
        """

        // When
        controller.send(body: body)
        controller.flush()

        // Then
        let logMatcher = try XCTUnwrap(core.waitAndReturnLogMatchers().first)
        try logMatcher.assertItFullyMatches(
            jsonString: """
        {
            "date": \(1_635_932_927_012 + 123.dd.toInt64Milliseconds),
            "atatusTags": "service:abc,version:1.1.1,sdk_version:abc,env:test",
            "message": "message",
            "session_id": "0110cab4-7471-480e-aa4e-7ce039ced355",
            "status": "debug",
            "view": {
                "referrer": "",
                "url": "https://atatus.dev/browser-sdk-test-playground"
            },
        }
        """
        )
    }

    func testWebLogWithRUMIntegration() throws {
        // Given
        let randomApplicationID: String = .mockRandom()
        let randomUUID: RUMUUID = .mockRandom()

        Logs.enable(in: core)
        RUM.enable(with: .mockWith(applicationID: randomApplicationID) {
            $0.uuidGenerator = RUMUUIDGeneratorMock(uuid: randomUUID)
        }, in: core)

        // Flush to ensure the AnonymousIdentifierManager has generated
        // and propagated the anonymous ID to the context
        core.flush()

        let body = """
        {
            "eventType": "log",
            "event": {
                "date" : \(1_635_932_927_012),
                "status": "debug",
                "message": "message",
                "session_id": "0110cab4-7471-480e-aa4e-7ce039ced355",
                "view": {
                    "referrer": "",
                    "url": "https://atatus.dev/browser-sdk-test-playground"
                }
            }
        }
        """

        // When
        RUMMonitor.shared(in: core).startView(key: "web-view")
        controller.send(body: body)
        controller.flush()

        // Then
        let expectedUUID = randomUUID.toRUMDataFormat
        let logMatcher = try XCTUnwrap(core.waitAndReturnLogMatchers().first)
        try logMatcher.assertItFullyMatches(
            jsonString: """
        {
            "date": \(1_635_932_927_012 + 123.dd.toInt64Milliseconds),
            "atatusTags": "service:abc,version:1.1.1,sdk_version:abc,env:test",
            "message": "message",
            "application_id": "\(randomApplicationID)",
            "session_id": "\(expectedUUID)",
            "view.id": "\(expectedUUID)",
            "status": "debug",
            "view": {
                "referrer": "",
                "url": "https://atatus.dev/browser-sdk-test-playground"
            },
            "usr": {
                "anonymous_id": "\(expectedUUID)"
            }
        }
        """
        )
    }
}

#endif
