/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import XCTest

import TestUtilities
@testable import AtatusInternal

class URLSessionDataDelegateSwizzlerTests: XCTestCase {
    func testSwizzling_implementedMethods() throws {
        let delegate = SessionDataDelegateMock()
        let didReceiveData = expectation(description: "didReceiveData")
        didReceiveData.assertForOverFulfill = false

        // Given
        let swizzler = URLSessionDataDelegateSwizzler()

        try swizzler.swizzle(
            delegateClass: SessionDataDelegateMock.self,
            interceptDidReceive: { _, _, _ in
                didReceiveData.fulfill()
            }
        )

        // When
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        session
            .dataTask(with: URL.mockAny())
            .resume() // intercepted

        wait(for: [didReceiveData], timeout: 5)
    }

    func testSwizzling_whenMethodsNotImplemented() throws {
        let delegate = SessionDataDelegateMock()
        let didReceiveData = expectation(description: "didReceiveData")
        didReceiveData.assertForOverFulfill = false

        // Given
        let swizzler = URLSessionDataDelegateSwizzler()

        try swizzler.swizzle(
            delegateClass: SessionDataDelegateMock.self,
            interceptDidReceive: { _, _, _ in
                didReceiveData.fulfill()
            }
        )

        // When
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        session
            .dataTask(with: URL.mockAny())
            .resume() // intercepted

        wait(for: [didReceiveData], timeout: 5)
    }

    func testUnSwizzling() throws {
        let delegate = SessionDataDelegateMock()
        let expectation = self.expectation(description: "not expected")
        expectation.isInverted = true

        // Given
        let swizzler = URLSessionDataDelegateSwizzler()

        try swizzler.swizzle(
            delegateClass: SessionDataDelegateMock.self,
            interceptDidReceive: { _, _, _ in
                expectation.fulfill()
            }
        )

        // When
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        session
            .dataTask(with: URL.mockAny())
            .resume() // not intercepted

        swizzler.unswizzle()

        waitForExpectations(timeout: 5)
    }
}
