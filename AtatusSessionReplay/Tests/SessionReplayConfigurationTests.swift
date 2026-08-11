/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

#if os(iOS)
import XCTest
@_spi(Internal)
@testable import TestUtilities
@_spi(Internal)
@testable import AtatusSessionReplay

class SessionReplayConfigurationTests: XCTestCase {
    func testDefaultConfiguration() {
        // When
        let config = SessionReplay.Configuration(
            textAndInputPrivacyLevel: .maskAll,
            imagePrivacyLevel: .maskAll,
            touchPrivacyLevel: .hide
        )

        // Then
        XCTAssertEqual(config.replaySampleRate, 100)
        XCTAssertEqual(config.textAndInputPrivacyLevel, .maskAll)
        XCTAssertEqual(config.imagePrivacyLevel, .maskAll)
        XCTAssertEqual(config.touchPrivacyLevel, .hide)
        XCTAssertEqual(config.startRecordingImmediately, true)
        XCTAssertNil(config.customEndpoint)
        XCTAssertEqual(config._additionalNodeRecorders.count, 0)
    }

    @available(iOS 13.0, tvOS 13.0, *)
    func testDefaultConfigurationDisablesCompositionTreeRecordingFeatureFlag() {
        // When
        let config = SessionReplay.Configuration()

        // Then
        XCTAssertFalse(config.featureFlags[.compositionTreeRecording])
    }

    func testDefaultConfigurationWithNewApi() {
        // When
        let config = SessionReplay.Configuration(
            textAndInputPrivacyLevel: .maskAll,
            imagePrivacyLevel: .maskAll,
            touchPrivacyLevel: .hide
        )

        // Then
        XCTAssertEqual(config.replaySampleRate, 100)
        XCTAssertEqual(config.textAndInputPrivacyLevel, .maskAll)
        XCTAssertEqual(config.imagePrivacyLevel, .maskAll)
        XCTAssertEqual(config.touchPrivacyLevel, .hide)
        XCTAssertEqual(config.startRecordingImmediately, true)
        XCTAssertNil(config.customEndpoint)
        XCTAssertEqual(config._additionalNodeRecorders.count, 0)
    }

    func testConfigurationWithAdditionalNodeRecorders() {
        let random: Float = .mockRandom(min: 0, max: 100)
        let mockNodeRecorder = SessionReplayNodeRecorderMock()

        // When
        var config = SessionReplay.Configuration(replaySampleRate: random)
        config.setAdditionalNodeRecorders([mockNodeRecorder])

        // Then
        XCTAssertEqual(config._additionalNodeRecorders.count, 1)
        XCTAssertEqual(config._additionalNodeRecorders[0].identifier, mockNodeRecorder.identifier)
    }

    func testConfigurationWithAdditionalNodeRecordersWithNewApi() {
        let mockNodeRecorder = SessionReplayNodeRecorderMock()

        // When
        var config = SessionReplay.Configuration(
            textAndInputPrivacyLevel: .maskAll,
            imagePrivacyLevel: .maskAll,
            touchPrivacyLevel: .hide
        )
        config.setAdditionalNodeRecorders([mockNodeRecorder])

        // Then
        XCTAssertEqual(config._additionalNodeRecorders.count, 1)
        XCTAssertEqual(config._additionalNodeRecorders[0].identifier, mockNodeRecorder.identifier)
    }
}
#endif
