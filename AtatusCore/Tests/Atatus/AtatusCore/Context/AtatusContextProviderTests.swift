/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed `dd*` types to `Atatus*`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities
@testable import AtatusCore

class AtatusContextProviderTests: XCTestCase {
    let context: AtatusContext = .mockAny()

    // MARK: - Test Propagation

    func testPublisherPropagation() throws {
        // Given
        let serverOffsetPublisher = ContextValuePublisherMock<TimeInterval>(initialValue: 0)
        let networkConnectionInfoPublisher = ContextValuePublisherMock<NetworkConnectionInfo?>()
        let carrierInfoPublisher = ContextValuePublisherMock<CarrierInfo?>()

        let provider = AtatusContextProvider(context: context)
        provider.subscribe(\.serverTimeOffset, to: serverOffsetPublisher)
        provider.subscribe(\.networkConnectionInfo, to: networkConnectionInfoPublisher)
        provider.subscribe(\.carrierInfo, to: carrierInfoPublisher)

        // When
        let serverTimeOffset: TimeInterval = .mockRandomInThePast()
        serverOffsetPublisher.value = serverTimeOffset

        let networkConnectionInfo: NetworkConnectionInfo = .mockRandom()
        networkConnectionInfoPublisher.value = networkConnectionInfo

        let carrierInfo: CarrierInfo = .mockRandom()
        carrierInfoPublisher.value = carrierInfo

        // Then
        let context = provider.read()
        XCTAssertEqual(context.serverTimeOffset, serverTimeOffset)
        XCTAssertEqual(context.networkConnectionInfo, networkConnectionInfo)
        XCTAssertEqual(context.carrierInfo, carrierInfo)
    }

    func testPublishNewContextOnValueChange() throws {
        let expectation = self.expectation(description: "publish new context")
        expectation.expectedFulfillmentCount = 3

        // Given
        let serverOffsetPublisher = ContextValuePublisherMock<TimeInterval>(initialValue: 0)

        let provider = AtatusContextProvider(context: context)
        provider.subscribe(\.serverTimeOffset, to: serverOffsetPublisher)

        provider.publish { _ in
            expectation.fulfill()
        }

        // When
        (0..<expectation.expectedFulfillmentCount).forEach { _ in
            serverOffsetPublisher.value = .mockRandomInThePast()
        }

        wait(for: [expectation], timeout: 0.5)
    }

    // MARK: - Thread Safety

    func testThreadSafety() {
        let serverOffsetPublisher = ContextValuePublisherMock<TimeInterval>(initialValue: 0)
        let networkConnectionInfoPublisher = ContextValuePublisherMock<NetworkConnectionInfo?>()
        let carrierInfoPublisher = ContextValuePublisherMock<CarrierInfo?>()

        let provider = AtatusContextProvider(context: context)

        provider.subscribe(\.serverTimeOffset, to: serverOffsetPublisher)
        provider.subscribe(\.networkConnectionInfo, to: networkConnectionInfoPublisher)
        provider.subscribe(\.carrierInfo, to: carrierInfoPublisher)

        // swiftlint:disable opening_brace
        callConcurrently(
            closures: [
                { serverOffsetPublisher.value = .mockRandom() },
                { networkConnectionInfoPublisher.value = .mockRandom() },
                { carrierInfoPublisher.value = .mockRandom() },
                { provider.read { _ in } },
                { provider.write { $0 = .mockAny() } }
            ],
            iterations: 1_000
        )
        // swiftlint:enable opening_brace
    }
}
