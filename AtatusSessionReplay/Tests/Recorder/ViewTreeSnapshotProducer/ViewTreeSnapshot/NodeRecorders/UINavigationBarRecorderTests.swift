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
import TestUtilities
@_spi(Internal)
@testable import AtatusSessionReplay

class UINavigationBarRecorderTests: XCTestCase {
    private let recorder = UINavigationBarRecorder(identifier: UUID())

    func testWhenViewIsOfExpectedType() throws {
        // Given
        let fixtures: [ViewAttributes.Fixture] = [
            .visible(.noAppearance),
            .visible(.someAppearance),
            .opaque
        ]

        let navigationBar = UINavigationBar.mock(withFixture: fixtures.randomElement()!)
        let viewAttributes = ViewAttributes(view: navigationBar, frame: navigationBar.frame, clip: navigationBar.frame, overrides: .mockAny())

        // When
        let semantics = try XCTUnwrap(recorder.semantics(of: navigationBar, with: viewAttributes, in: .mockAny()) as? SpecificElement)

        // Then
        XCTAssertEqual(semantics.subtreeStrategy, .record)
    }

    func testWhenViewIsNotOfExpectedType() {
        // When
        let view = UITextField()

        // Then
        XCTAssertNil(recorder.semantics(of: view, with: .mockAny(), in: .mockAny()))
    }
}
#endif
