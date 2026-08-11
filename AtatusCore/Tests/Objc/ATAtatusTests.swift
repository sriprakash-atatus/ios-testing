/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`, `ddLogs` -> `AtatusLogs`; renamed the `DD` symbol prefix to `AT`; renamed
// `clientToken` to `licenseKey`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

import XCTest
import TestUtilities

@testable import AtatusInternal
@testable import AtatusLogs
@_spi(objc)
@testable import AtatusCore

/// These tests verify that Objc APIs properly interact with`Atatus` public API (swift).
class ATAtatusTests: XCTestCase {
    override func setUp() {
        super.setUp()
        XCTAssertFalse(Atatus.isInitialized())
    }

    override func tearDown() {
        XCTAssertFalse(Atatus.isInitialized())
        super.tearDown()
    }

    // MARK: - SDK initialization / stop lifecycle

    func testItForwardsInitializationToSwift() throws {
        let config = objc_Configuration(
            licenseKey: "abcefghi",
            env: "tests"
        )

        config.bundle = .mockWith(CFBundleExecutable: "app-name")

        objc_Atatus.initialize(
            configuration: config,
            trackingConsent: randomConsent().objc
        )

        XCTAssertTrue(Atatus.isInitialized())

        let context = try XCTUnwrap(CoreRegistry.default as? AtatusCore).contextProvider.read()
        XCTAssertEqual(context.applicationName, "app-name")
        XCTAssertEqual(context.env, "tests")

        Atatus.flushAndDeinitialize()

        XCTAssertNil(CoreRegistry.default.get(feature: LogsFeature.self))
    }

    func testItReflectsInitializationStatus() throws {
        let config = objc_Configuration(
            licenseKey: "abcefghi",
            env: "tests"
        )

        config.bundle = .mockWith(CFBundleExecutable: "app-name")
        XCTAssertFalse(objc_Atatus.isInitialized())

        objc_Atatus.initialize(
            configuration: config,
            trackingConsent: randomConsent().objc
        )

        XCTAssertTrue(objc_Atatus.isInitialized())

        Atatus.flushAndDeinitialize()

        XCTAssertNil(CoreRegistry.default.get(feature: LogsFeature.self))
    }

    func testItForwardsStopInstanceToSwift() throws {
        let config = objc_Configuration(
            licenseKey: "abcefghi",
            env: "tests"
        )

        config.bundle = .mockWith(CFBundleExecutable: "app-name")

        objc_Atatus.initialize(
            configuration: config,
            trackingConsent: randomConsent().objc
        )

        XCTAssertTrue(Atatus.isInitialized())

        objc_Atatus.stopInstance()

        XCTAssertFalse(Atatus.isInitialized())

        XCTAssertNil(CoreRegistry.default.get(feature: LogsFeature.self))
    }

    // MARK: - Changing Tracking Consent

    func testItForwardsTrackingConsentToSwift() {
        let initialConsent = randomConsent()
        let nextConsent = randomConsent()

        objc_Atatus.initialize(
            configuration: objc_Configuration(licenseKey: "abcefghi", env: "tests"),
            trackingConsent: initialConsent.objc
        )

        let core = CoreRegistry.default as? AtatusCore
        XCTAssertEqual(core?.consentPublisher.consent, initialConsent.swift)

        objc_Atatus.setTrackingConsent(consent: nextConsent.objc)

        XCTAssertEqual(core?.consentPublisher.consent, nextConsent.swift)

        Atatus.flushAndDeinitialize()
    }

    // MARK: - Setting user info

    func testItForwardsUserInfoToSwift() throws {
        objc_Atatus.initialize(
            configuration: objc_Configuration(licenseKey: "abcefghi", env: "tests"),
            trackingConsent: randomConsent().objc
        )

        let core = CoreRegistry.default as? AtatusCore
        let userInfo = try XCTUnwrap(core?.userInfoPublisher)

        objc_Atatus.setUserInfo(
            userId: "id",
            name: "name",
            email: "email",
            extraInfo: [
                "attribute-int": 42,
                "attribute-double": 42.5,
                "attribute-string": "string value"
            ]
        )
        objc_Atatus.addUserExtraInfo(["foo": "bar"])
        XCTAssertEqual(userInfo.current.id, "id")
        XCTAssertEqual(userInfo.current.name, "name")
        XCTAssertEqual(userInfo.current.email, "email")
        let extraInfo = userInfo.current.extraInfo
        XCTAssertEqual(extraInfo["attribute-int"]?.dd.decode(), 42)
        XCTAssertEqual(extraInfo["attribute-double"]?.dd.decode(), 42.5)
        XCTAssertEqual(extraInfo["attribute-string"]?.dd.decode(), "string value")
        XCTAssertEqual(extraInfo["foo"]?.dd.decode(), "bar")

        objc_Atatus.setUserInfo(userId: "id", name: nil, email: nil, extraInfo: [:])
        XCTAssertNotNil(userInfo.current.id)
        XCTAssertNil(userInfo.current.name)
        XCTAssertNil(userInfo.current.email)
        XCTAssertTrue(userInfo.current.extraInfo.isEmpty)

        Atatus.flushAndDeinitialize()
    }

    // MARK: - Changing SDK verbosity level

    private let swiftVerbosityLevels: [CoreLoggerLevel?] = [
        .debug, .warn, .error, .critical, nil
    ]
    private let objcVerbosityLevels: [objc_CoreLoggerLevel] = [
        .debug, .warn, .error, .critical, .none
    ]

    func testItForwardsSettingVerbosityLevelToSwift() {
        defer { Atatus.verbosityLevel = nil }

        zip(swiftVerbosityLevels, objcVerbosityLevels).forEach { swiftLevel, objcLevel in
            objc_Atatus.setVerbosityLevel(objcLevel)
            XCTAssertEqual(Atatus.verbosityLevel, swiftLevel)
        }
    }

    func testItGetsVerbosityLevelFromSwift() {
        defer { Atatus.verbosityLevel = nil }

        zip(swiftVerbosityLevels, objcVerbosityLevels).forEach { swiftLevel, objcLevel in
            Atatus.verbosityLevel = swiftLevel
            XCTAssertEqual(objc_Atatus.verbosityLevel(), objcLevel)
        }
    }

    // MARK: - Helpers

    private func randomConsent() -> (objc: objc_TrackingConsent, swift: TrackingConsent) {
        let objcConsents: [objc_TrackingConsent] = [.granted(), .notGranted(), .pending()]
        let swiftConsents: [TrackingConsent] = [.granted, .notGranted, .pending]
        let index: Int = .random(in: 0..<3)
        return (objc: objcConsents[index], swift: swiftConsents[index])
    }
}
