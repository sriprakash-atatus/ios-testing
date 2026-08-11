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

class UIViewRecorderTests: XCTestCase {
    private let recorder = UIViewRecorder(identifier: UUID())
    /// The view under test.
    private let view = UIView()
    /// `ViewAttributes` simulating common attributes of the view.
    private var viewAttributes: ViewAttributes = .mockAny()

    func testWhenViewIsNotVisible() throws {
        // When
        viewAttributes = .mock(fixture: .invisible)

        // Then
        let semantics = try XCTUnwrap(recorder.semantics(of: view, with: viewAttributes, in: .mockAny()))
        XCTAssertTrue(semantics is InvisibleElement)
    }

    func testWhenViewIsVisibleAndHasSomeAppearance() throws {
        // When
        viewAttributes = .mock(fixture: .visible(.someAppearance))

        // Then
        let semantics = try XCTUnwrap(recorder.semantics(of: view, with: viewAttributes, in: .mockAny()))
        XCTAssertTrue(semantics is AmbiguousElement)
        XCTAssertTrue(semantics.nodes.first?.wireframesBuilder is UIViewWireframesBuilder)
    }

    func testWhenViewIsVisibleButHasNoAppearance() throws {
        // When
        viewAttributes = .mock(fixture: .visible(.noAppearance))

        // Then
        let semantics = try XCTUnwrap(recorder.semantics(of: view, with: viewAttributes, in: .mockAny()))
        XCTAssertTrue(semantics is InvisibleElement)
        XCTAssertEqual(semantics.subtreeStrategy, .record)
    }

    func testWhenViewIsFromUIAlertController() throws {
        // When
        viewAttributes = .mockRandom()

        // Then
        var context = ViewTreeRecordingContext.mockRandom()
        context.viewControllerContext.isRootView = true
        context.viewControllerContext.parentType = .alert
        let semantics = try XCTUnwrap(recorder.semantics(of: view, with: viewAttributes, in: context))
        XCTAssertTrue(semantics is AmbiguousElement)
        XCTAssertEqual(semantics.subtreeStrategy, .record)
    }

    func testWhenViewHasHiddenOverride() throws {
        // Given
        viewAttributes = .mock(fixture: .visible(.someAppearance))
        viewAttributes.hide = true

        // When
        let semantics = try XCTUnwrap(recorder.semantics(of: view, with: viewAttributes, in: .mockAny()))

        // Then
        XCTAssertTrue(semantics is SpecificElement)
        XCTAssertEqual(semantics.subtreeStrategy, .ignore)
        XCTAssertTrue(semantics.nodes.first?.wireframesBuilder is UIViewWireframesBuilder)
    }
}
#endif
