/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddRUM` -> `AtatusRUM`, `ddSessionReplay`
// -> `AtatusSessionReplay`, `ddWebViewTracking` -> `AtatusWebViewTracking`; renamed `dd*` types
// to `Atatus*`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest

#if os(iOS)
import WebKit

import TestUtilities
@testable import AtatusRUM
@testable import AtatusWebViewTracking
@_spi(Internal)
@testable import AtatusSessionReplay

class WebRecordIntegrationTests: XCTestCase {
    // swiftlint:disable implicitly_unwrapped_optional
    private var core: AtatusCoreProxy!
    private var webView: WKWebView!
    private var controller: WKUserContentControllerMock!
    // swiftlint:enable implicitly_unwrapped_optional

    override func setUp() {
        core = AtatusCoreProxy(
            context: .mockWith(
                env: "test",
                version: "1.1.1",
                serverTimeOffset: 123
            )
        )

        controller = WKUserContentControllerMock()
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool() // do not share cookies between instances: prevent leak
        configuration.userContentController = controller
        webView = WKWebView(frame: .zero, configuration: configuration)
        WebViewTracking.enable(webView: webView, in: core)
    }

    override func tearDownWithError() throws {
        WebViewTracking.disable(webView: webView)
        try core.flushAndTearDown()
        core = nil
        webView = nil
        controller = nil
    }

    func testWebRecordIntegration() throws {
        // Given
        let randomApplicationID: String = .mockRandom()
        let randomUUID: RUMUUID = .mockRandom()
        let randomBrowserViewID: UUID = .mockRandom()

        let config = SessionReplay.Configuration(
            replaySampleRate: 100,
            textAndInputPrivacyLevel: .maskAll,
            imagePrivacyLevel: .maskAll,
            touchPrivacyLevel: .show
        )
        SessionReplay.enable(with: config, in: core)
        RUM.enable(with: .mockWith(applicationID: randomApplicationID) {
            $0.uuidGenerator = RUMUUIDGeneratorMock(uuid: randomUUID)
        }, in: core)

        let rumBody = """
        {
            "eventType": "rum",
                "event": {
                    "date": \(1_635_932_927_012),
                    "type": "view",
                    "application": { "id": "\(randomApplicationID)" },
                    "session": { "id": "\(randomUUID.toRUMDataFormat)" },
                    "view": { "id": "\(randomBrowserViewID.uuidString.lowercased())" }
            }
        }
        """

        let body = """
        {
            "eventType": "record",
            "event": {
                "timestamp" : \(1_635_932_927_012),
                "type": 2
            },
            "view": { "id": "\(randomBrowserViewID.uuidString.lowercased())" }
        }
        """

        // When
        RUMMonitor.shared(in: core).startView(key: "web-view")
        controller.send(body: rumBody, from: webView)
        controller.flush()
        _ = core.waitAndReturnEventsData(ofFeature: RUMFeature.name) // Wait for context propagation
        controller.send(body: body, from: webView)
        controller.flush()

        // Then
        let segments = try core.waitAndReturnEventsData(ofFeature: SessionReplayFeature.name)
            .map { try SegmentJSON($0, source: .ios) }
        let segment = try XCTUnwrap(segments.first)

        let expectedUUID = randomUUID.toRUMDataFormat
        let expectedSlotID = String(webView.hash)

        XCTAssertEqual(segment.applicationID, randomApplicationID)
        XCTAssertEqual(segment.sessionID, expectedUUID)
        XCTAssertEqual(segment.viewID, randomBrowserViewID.uuidString.lowercased())

        let record = try XCTUnwrap(segment.records.first)
        ATAssertDictionariesEqual(record, [
            "timestamp": 1_635_932_927_012 + 123.dd.toInt64Milliseconds,
            "type": 2,
            "slotId": expectedSlotID
        ])
    }

    func testWebRecordIntegrationWithNewSessionReplayConfigurationAPI() throws {
        // Given
        let randomApplicationID: String = .mockRandom()
        let randomUUID: RUMUUID = .mockRandom()
        let randomBrowserViewID: UUID = .mockRandom()

        SessionReplay.enable(with: SessionReplay.Configuration(
            replaySampleRate: 100,
            textAndInputPrivacyLevel: .mockRandom(),
            imagePrivacyLevel: .mockRandom(),
            touchPrivacyLevel: .mockRandom()
        ), in: core)
        RUM.enable(with: .mockWith(applicationID: randomApplicationID) {
            $0.uuidGenerator = RUMUUIDGeneratorMock(uuid: randomUUID)
        }, in: core)

        let rumBody = """
        {
            "eventType": "rum",
                "event": {
                    "date": \(1_635_932_927_012),
                    "type": "view",
                    "application": { "id": "\(randomApplicationID)" },
                    "session": { "id": "\(randomUUID.toRUMDataFormat)" },
                    "view": { "id": "\(randomBrowserViewID.uuidString.lowercased())" }
            }
        }
        """

        let body = """
        {
            "eventType": "record",
            "event": {
                "timestamp" : \(1_635_932_927_012),
                "type": 2
            },
            "view": { "id": "\(randomBrowserViewID.uuidString.lowercased())" }
        }
        """

        // When
        RUMMonitor.shared(in: core).startView(key: "web-view")
        controller.send(body: rumBody, from: webView)
        controller.flush()
        _ = core.waitAndReturnEventsData(ofFeature: RUMFeature.name) // Wait for context propagation
        controller.send(body: body, from: webView)
        controller.flush()

        // Then
        let segments = try core.waitAndReturnEventsData(ofFeature: SessionReplayFeature.name)
            .map { try SegmentJSON($0, source: .ios) }
        let segment = try XCTUnwrap(segments.first)

        let expectedUUID = randomUUID.toRUMDataFormat
        let expectedSlotID = String(webView.hash)

        XCTAssertEqual(segment.applicationID, randomApplicationID)
        XCTAssertEqual(segment.sessionID, expectedUUID)
        XCTAssertEqual(segment.viewID, randomBrowserViewID.uuidString.lowercased())

        let record = try XCTUnwrap(segment.records.first)
        ATAssertDictionariesEqual(record, [
            "timestamp": 1_635_932_927_012 + 123.dd.toInt64Milliseconds,
            "type": 2,
            "slotId": expectedSlotID
        ])
    }
}

#endif
