/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#if os(iOS)
import XCTest
@_spi(Internal)
import TestUtilities
@_spi(Internal)
@testable import AtatusSessionReplay

class UITabBarRecorderTests: XCTestCase {
    private let recorder = UITabBarRecorder(identifier: UUID())

    func testWhenViewIsOfExpectedType() throws {
        // When
        let tabBar = UITabBar.mock(withFixture: .allCases.randomElement()!)
        let viewAttributes = ViewAttributes(view: tabBar, frame: tabBar.frame, clip: tabBar.frame, overrides: .mockAny())

        // Then
        let semantics = try XCTUnwrap(recorder.semantics(of: tabBar, with: viewAttributes, in: .mockAny()))
        XCTAssertTrue(semantics is SpecificElement)
        XCTAssertEqual(semantics.subtreeStrategy, .ignore)
        XCTAssertTrue(semantics.nodes.first?.wireframesBuilder is UITabBarWireframesBuilder)
    }

    func testWhenViewIsNotOfExpectedType() {
        // When
        let view = UITextField()

        // Then
        XCTAssertNil(recorder.semantics(of: view, with: .mockAny(), in: .mockAny()))
    }

    func testWhenRecordingSubviewTwice() {
        // Given
        let tabBar = UITabBar.mock(withFixture: .visible(.someAppearance))
        tabBar.items = [UITabBarItem(title: "first", image: UIImage(), tag: 0)]
        let viewAttributes = ViewAttributes(view: tabBar, frame: tabBar.frame, clip: tabBar.frame, overrides: .mockAny())

        // When
        let semantics1 = recorder.semantics(of: tabBar, with: viewAttributes, in: .mockAny())
        let semantics2 = recorder.semantics(of: tabBar, with: viewAttributes, in: .mockAny())

        let builder = SessionReplayWireframesBuilder()
        let wireframes1 = semantics1?.nodes.flatMap { $0.wireframesBuilder.buildWireframes(with: builder) }
        let wireframes2 = semantics2?.nodes.flatMap { $0.wireframesBuilder.buildWireframes(with: builder) }

        // Then
        ATAssertReflectionEqual(wireframes1, wireframes2)
    }
}
#endif
