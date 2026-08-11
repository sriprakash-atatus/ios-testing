/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddFlags` -> `AtatusFlags`, `ddInternal`
// -> `AtatusInternal`, `ddRUM` -> `AtatusRUM`; renamed `dd*` types to `Atatus*`; rebranded the
// licence header.

import XCTest
import TestUtilities
import AtatusInternal

@_spi(Internal)
@testable import AtatusFlags
@testable import AtatusRUM

/// Covers integration scenarios between Flags and RUM features.
final class FlagsRUMIntegrationTests: XCTestCase {
    private enum Fixtures {
        static let flagsData = FlagsData(
            flags: [
                "string-flag": .init(
                    allocationKey: "allocation-123",
                    variationKey: "variation-123",
                    variation: .string("red"),
                    reason: "TARGETING_MATCH",
                    doLog: true
                ),
                "boolean-flag": .init(
                    allocationKey: "allocation-124",
                    variationKey: "variation-124",
                    variation: .boolean(true),
                    reason: "TARGETING_MATCH",
                    doLog: true
                )
            ],
            context: .init(
                targetingKey: "user-123",
                attributes: ["foo": .string("bar")]
            ),
            date: .mockAny()
        )
    }

    private var core: AtatusCoreProxy! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUp() {
        super.setUp()

        core = AtatusCoreProxy(context: .mockWith(trackingConsent: .granted))

        RUM.enable(with: .init(applicationID: "test-app-id"), in: core)
        Flags.enable(in: core)

        let featureScope = core.scope(for: FlagsFeature.self)
        featureScope.flagsDataStore.setFlagsData(Fixtures.flagsData, forClientNamed: FlagsClient.defaultName)
        featureScope.dataStore.flush()
    }

    override func tearDownWithError() throws {
        let featureScope = core.scope(for: FlagsFeature.self)
        featureScope.dataStore.clearAllData()

        try core.flushAndTearDown()
        core = nil

        super.tearDown()
    }

    func testWhenFlagIsEvaluated_itAddsFeatureFlagToRUMView() throws {
        // Given
        let monitor = RUMMonitor.shared(in: core)
        let client = FlagsClient.create(in: core)

        // When
        monitor.startView(key: "test-view", name: "Test View")

        let featureScope = core.scope(for: FlagsFeature.self)
        featureScope.dataStore.flush()

        let boolValue = client.getBooleanValue(key: "boolean-flag", defaultValue: false)
        let stringValue = client.getStringValue(key: "string-flag", defaultValue: "blue")

        core.flush()

        monitor.stopView(key: "test-view")

        // Then
        let rumEvents = core.waitAndReturnEvents(
            ofFeature: RUMFeature.name,
            ofType: RUMViewEvent.self
        )
        let viewEvent = try XCTUnwrap(
            rumEvents.last,
            "Should have at least one view event"
        )
        let featureFlags = try XCTUnwrap(
            viewEvent.featureFlags?.featureFlagsInfo,
            "View should have feature flags"
        )

        XCTAssertEqual(featureFlags.count, 2)
        XCTAssertEqual(featureFlags["boolean-flag"] as? String, "variation-124")
        XCTAssertEqual(featureFlags["string-flag"] as? String, "variation-123")
    }
}
