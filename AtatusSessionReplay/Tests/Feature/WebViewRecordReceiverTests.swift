/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddSessionReplay` -> `AtatusSessionReplay`; renamed the `DD` symbol prefix to `AT`; rebranded the
// licence header.

#if os(iOS)

import XCTest
import TestUtilities

@testable import AtatusInternal
@testable import AtatusSessionReplay

class WebViewRecordReceiverTests: XCTestCase {
    func testGivenRUMContextAvailable_whenReceivingWebRecord_itCreatesSegment() throws {
        let browserViewID: String = .mockRandom()
        let serverTimeOffset: TimeInterval = .mockRandom(min: -10, max: 10).rounded()

        let rumContext: RUMCoreContext = .mockAny()
        let webViewContext: RUMWebViewContext = .mockWith(
            serverTimeOffsets: [browserViewID: serverTimeOffset]
        )

        let scope = FeatureScopeMock(
            context: .mockWith(
                source: "react-native",
                additionalContext: [rumContext, webViewContext]
            )
        )

        // Given
        let receiver = WebViewRecordReceiver(
            scope: scope
        )

        let random = mockRandomAttributes() // because below we only mock partial web event, we use this random to make the test fuzzy
        let webRecordMock: [String: Any] = [
            "timestamp": 100_000,
            "type": 2
        ].merging(random, uniquingKeysWith: { old, _ in old })

        // When

        let message = WebViewMessage.record(webRecordMock, WebViewMessage.View(id: browserViewID))
        let result = receiver.receive(message: .webview(message), from: NOPAtatusCore())

        // Then
        let expectedWebSegmentWritten: [String: Any] = [
            "applicationID": rumContext.applicationID,
            "sessionID": rumContext.sessionID,
            "viewID": browserViewID,
            "records": [
                [
                    "timestamp": 100_000 + serverTimeOffset.dd.toInt64Milliseconds,
                    "type": 2
                ].merging(random, uniquingKeysWith: { old, _ in old })
            ]
        ]

        XCTAssertTrue(result, "It must accept the message")
        XCTAssertEqual(scope.eventsWritten.count, 1, "It must write web segment to core")
        let actualWebEventWritten = try XCTUnwrap(scope.eventsWritten.first)
        ATAssertJSONEqual(AnyCodable(actualWebEventWritten), AnyCodable(expectedWebSegmentWritten))
    }

    func testGivenRUMContextNotAvailable_whenReceivingWebRecord_itIsDropped() throws {
        let scope = FeatureScopeMock()

        // Given
        XCTAssertNil(scope.contextMock.additionalContext(ofType: RUMCoreContext.self))

        let receiver = WebViewRecordReceiver(scope: scope)

        // When
        let record = WebViewMessage.record(mockRandomAttributes(), WebViewMessage.View(id: .mockRandom()))
        let result = receiver.receive(message: .webview(record), from: NOPAtatusCore())

        // Then
        XCTAssertTrue(result, "It must accept the message")
        XCTAssertTrue(scope.eventsWritten.isEmpty, "The event must be dropped")
    }

    func testWhenReceivingOtherMessage_itRejectsIt() throws {
        let scope = FeatureScopeMock()

        // Given
        let receiver = WebViewRecordReceiver(scope: scope)

        // When
        let otherMessage: FeatureMessage = .payload(String.mockRandom())
        let result = receiver.receive(message: otherMessage, from: NOPAtatusCore())

        // Then
        XCTAssertFalse(result, "It must reject messages addressed to other receivers")
    }
}

#endif
