/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusCore

class MessageBusTests: XCTestCase {
    func testMessageBus() throws {
        let expectation = XCTestExpectation(description: "dispatch message")
        expectation.expectedFulfillmentCount = 2

        // Given
        let core = PassthroughCoreMock()

        let receiver = FeatureMessageReceiverMock { message in
            // Then
            switch message {
            case let .payload(payload as String) where payload == "value":
                expectation.fulfill()
            default:
                XCTFail("wrong message case")
            }
        }

        let bus = MessageBus()
        bus.connect(core: core)

        bus.connect(receiver, forKey: "receiver 1")
        bus.connect(receiver, forKey: "receiver 2")

        // When
        bus.send(message: .payload("value"))

        // Then
        wait(for: [expectation], timeout: 0.5)
        bus.flush()
    }

    func testItForwardConfigurationAfterDispatch() throws {
        let expectation = XCTestExpectation(description: "dispatch configuration")
        let receiver = FeatureMessageReceiverMock { message in
            guard
                case .telemetry(let telemetry) = message,
                case .configuration(let configuration) = telemetry
            else {
                return XCTFail("Message bus should send configuration telemetry")
            }

            XCTAssertEqual(configuration.batchSize, 1)
            XCTAssertTrue(configuration.trackErrors ?? false)
            expectation.fulfill()
        }

        // Given
        let core = PassthroughCoreMock()
        let bus = MessageBus(configurationDispatchTime: .milliseconds(90))
        bus.connect(core: core)
        bus.connect(receiver, forKey: "test")

        // When
        bus.configuration(batchSize: 1)
        bus.configuration(trackErrors: true)

        // Then
        wait(for: [expectation], timeout: 0.5)
        bus.flush()
    }
}

extension MessageBus: @retroactive Telemetry {
    public func send(telemetry: AtatusInternal.TelemetryMessage) {
        send(message: .telemetry(telemetry))
    }
}
