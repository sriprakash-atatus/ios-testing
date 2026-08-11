/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`,
// `ddCrashReporting` -> `AtatusCrashReporting`, `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities

@testable import AtatusCore
@testable import AtatusCrashReporting

class CrashContextTests: XCTestCase {
    /// This must be the exact encoder used to encode `CrashContext` in production code.
    private let encoder = CrashReportingFeature.crashContextEncoder
    /// This must be the exact decoder used to decode `CrashContext` in production code.
    private let decoder = CrashReportingFeature.crashContextDecoder

    func testGivenContextWithTrackingConsentSet_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomConsent: TrackingConsent = .mockRandom()

        // Given
        let context: CrashContext = .mockWith(trackingConsent: randomConsent)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        XCTAssertEqual(deserializedContext.trackingConsent, randomConsent)
    }

    func testGivenContextWithLastRUMViewEventSet_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomRUMViewEvent: RUMViewEvent = .mockRandom()

        // Given
        let context: CrashContext = .mockWith(lastRUMViewEvent: randomRUMViewEvent)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        ATAssertJSONEqual(
            deserializedContext.lastRUMViewEvent,
            randomRUMViewEvent
        )
    }

    func testGivenContextWithLastRUMSessionStateSet_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomRUMSessionState: RUMSessionState? = Bool.random() ? .mockRandom() : nil

        // Given
        let context: CrashContext = .mockWith(lastRUMSessionState: randomRUMSessionState)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        ATAssertJSONEqual(
            deserializedContext.lastRUMSessionState,
            randomRUMSessionState
        )
    }

    func testGivenContextWithLastRUMAttributesSet_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomRUMAttributes: RUMEventAttributes? = Bool.random() ? .mockRandom() : nil

        // Given
        let context: CrashContext = .mockWith(lastRUMAttributes: randomRUMAttributes)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        ATAssertJSONEqual(
            deserializedContext.lastRUMAttributes,
            randomRUMAttributes
        )
    }

    func testGivenContextWithLastLogttributesSet_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomLogAttributes: LogEventAttributes? = Bool.random() ? .mockRandom() : nil

        // Given
        let context: CrashContext = .mockWith(lastLogAttributes: randomLogAttributes)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        ATAssertJSONEqual(
            deserializedContext.lastLogAttributes,
            randomLogAttributes
        )
    }

    func testGivenContextWithUserInfoSet_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomUserInfo: UserInfo = .mockRandom()

        // Given
        let context: CrashContext = .mockWith(userInfo: randomUserInfo)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        XCTAssertEqual(deserializedContext.userInfo?.id, randomUserInfo.id)
        XCTAssertEqual(deserializedContext.userInfo?.name, randomUserInfo.name)
        XCTAssertEqual(deserializedContext.userInfo?.email, randomUserInfo.email)

        ATAssertJSONEqual(
            deserializedContext.userInfo!.extraInfo.mapValues { AnyEncodable($0) },
            randomUserInfo.extraInfo.mapValues { AnyEncodable($0) }
        )
    }

    func testGivenContextWithNetworkConnectionInfoSet_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomNetworkConnectionInfo: NetworkConnectionInfo = .mockRandom()

        // Given
        let context: CrashContext = .mockWith(networkConnectionInfo: randomNetworkConnectionInfo)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        XCTAssertEqual(deserializedContext.networkConnectionInfo, randomNetworkConnectionInfo)
    }

    func testGivenContextWithCarrierInfoSet_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomCarrierInfo: CarrierInfo = .mockRandom()

        // Given
        let context: CrashContext = .mockWith(carrierInfo: randomCarrierInfo)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        XCTAssertEqual(deserializedContext.carrierInfo, randomCarrierInfo)
    }

    func testGivenContextWithIsAppInForeground_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomIsAppInForeground: Bool = .mockRandom()

        // Given
        let context: CrashContext = .mockWith(lastIsAppInForeground: randomIsAppInForeground)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        XCTAssertEqual(deserializedContext.lastIsAppInForeground, randomIsAppInForeground)
    }

    func testGivenContextWithAppLaunchDate_whenItGetsEncoded_thenTheValueIsPreservedAfterDecoding() throws {
        let randomDate: Date = .mockRandom()

        // Given
        let context: CrashContext = .mockWith(appLaunchDate: randomDate)

        // When
        let serializedContext = try encoder.encode(context)

        // Then
        let deserializedContext = try decoder.decode(CrashContext.self, from: serializedContext)
        XCTAssertEqual(
            deserializedContext.appLaunchDate!.timeIntervalSince1970,
            randomDate.timeIntervalSince1970,
            accuracy: 0.001 // assert with ms precision as we encode dates as ISO8601 string which is lossfull
        )
    }
}
