/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest
import TestUtilities
@_spi(objc)
@testable import AtatusInternal
@testable import AtatusCore

class ATInternalLoggerTests: XCTestCase {
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

    func testObjcTelemetryDebugCallsTelemetryDebug() throws {
        CoreRegistry.register(default: core)
        defer { CoreRegistry.unregisterDefault() }

        // Given
        let id: String = .mockAny()
        let message: String = .mockAny()

        // When
        objc_InternalLogger.telemetryDebug(id: id, message: message)

        // Then
        XCTAssertEqual(telemetry.messages.count, 1)
        let debug = try XCTUnwrap(telemetry.messages.first?.asDebug, "A debug should be send to `telemetry`.")
        XCTAssertEqual(debug.id, id)
        XCTAssertEqual(debug.message, message)
    }

    func testObjcTelemetryErrorCallsTelemetryError() throws {
        CoreRegistry.register(default: core)
        defer { CoreRegistry.unregisterDefault() }

        // Given
        let id: String = .mockAny()
        let message: String = .mockAny()
        let stack: String = .mockAny()
        let kind: String = .mockAny()

        // When
        objc_InternalLogger.telemetryError(id: id, message: message, kind: kind, stack: stack)

        // Then
        XCTAssertEqual(telemetry.messages.count, 1)

        let error = try XCTUnwrap(telemetry.messages.first?.asError, "An error should be send to `telemetry`.")
        XCTAssertEqual(error.id, id)
        XCTAssertEqual(error.message, message)
        XCTAssertEqual(error.kind, kind)
        XCTAssertEqual(error.stack, stack)
    }

    func testWhenTelemetryIsSentThroughObjc_thenItForwardsToDDTelemetry() throws {
        CoreRegistry.register(default: core)
        defer { CoreRegistry.unregisterDefault() }

        // When
        let randomDebugMessage: String = .mockRandom()
        let randomErrorMessage: String = .mockRandom()
        objc_InternalLogger.telemetryDebug(id: .mockAny(), message: randomDebugMessage)
        objc_InternalLogger.telemetryError(id: .mockAny(), message: randomErrorMessage, kind: .mockAny(), stack: .mockAny())

        // Then
        XCTAssertEqual(telemetry.messages.count, 2)

        let debug = try XCTUnwrap(telemetry.messages.first?.asDebug, "A debug should be send to `telemetry`.")
        XCTAssertEqual(debug.message, randomDebugMessage)

        let error = try XCTUnwrap(telemetry.messages.last?.asError, "An error should be send to `telemetry`.")
        XCTAssertEqual(error.message, randomErrorMessage)
    }
}
