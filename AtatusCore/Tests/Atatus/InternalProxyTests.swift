/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence
// header.

import Foundation
import XCTest
import TestUtilities
import AtatusInternal
@testable import AtatusCore

class InternalProxyTests: XCTestCase {
    let telemetry = TelemetryReceiverMock()

    private var core: PassthroughCoreMock! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUp() {
        super.setUp()
        core = PassthroughCoreMock(messageReceiver: telemetry)
    }

    override func tearDown() {
        core = nil
        super.tearDown()
    }

    func testProxyDebugCallsTelemetryDebug() throws {
        CoreRegistry.register(default: core)
        defer { CoreRegistry.unregisterDefault() }

        // Given
        let id: String = .mockAny()
        let message: String = .mockAny()

        // When
        Atatus._internal.telemetry.debug(id: id, message: message)

        // Then
        XCTAssertEqual(telemetry.messages.count, 1)
        let debug = try XCTUnwrap(telemetry.messages.first?.asDebug, "A debug should be send to `telemetry`.")
        XCTAssertEqual(debug.id, id)
        XCTAssertEqual(debug.message, message)
    }

    func testProxyErrorCallsTelemetryError() throws {
        CoreRegistry.register(default: core)
        defer { CoreRegistry.unregisterDefault() }

        // Given
        let id: String = .mockAny()
        let message: String = .mockAny()
        let stack: String = .mockAny()
        let kind: String = .mockAny()

        // When
        Atatus._internal.telemetry.error(id: id, message: message, kind: kind, stack: stack)

        // Then
        XCTAssertEqual(telemetry.messages.count, 1)

        let error = try XCTUnwrap(telemetry.messages.first?.asError, "An error should be send to `telemetry`.")
        XCTAssertEqual(error.id, id)
        XCTAssertEqual(error.message, message)
        XCTAssertEqual(error.kind, kind)
        XCTAssertEqual(error.stack, stack)
    }

    func testWhenTelemetryIsSentThroughProxy_thenItForwardsToDDTelemetry() throws {
        CoreRegistry.register(default: core)
        defer { CoreRegistry.unregisterDefault() }

        // When
        let randomDebugMessage: String = .mockRandom()
        let randomErrorMessage: String = .mockRandom()
        Atatus._internal.telemetry.debug(id: .mockAny(), message: randomDebugMessage)
        Atatus._internal.telemetry.error(id: .mockAny(), message: randomErrorMessage, kind: .mockAny(), stack: .mockAny())

        // Then
        XCTAssertEqual(telemetry.messages.count, 2)

        let debug = try XCTUnwrap(telemetry.messages.first?.asDebug, "A debug should be send to `telemetry`.")
        XCTAssertEqual(debug.message, randomDebugMessage)

        let error = try XCTUnwrap(telemetry.messages.last?.asError, "An error should be send to `telemetry`.")
        XCTAssertEqual(error.message, randomErrorMessage)
    }

    func testWhenNewVersionIsSetInConfigurationProxy_thenItChangesAppVersionInCore() throws {
        // Given
        Atatus.initialize(
            with: .mockAny(),
            trackingConsent: .mockRandom()
        )
        defer { Atatus.flushAndDeinitialize() }

        // When
        let randomVersion: String = .mockRandom()
        Atatus._internal.set(customVersion: randomVersion)

        // Then
        let core = try XCTUnwrap(CoreRegistry.default as? AtatusCore)
        XCTAssertEqual(core.applicationVersionPublisher.version, randomVersion)
    }
}
