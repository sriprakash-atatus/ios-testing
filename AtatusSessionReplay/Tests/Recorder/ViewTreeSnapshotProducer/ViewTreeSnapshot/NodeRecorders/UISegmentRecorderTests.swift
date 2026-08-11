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

class UISegmentRecorderTests: XCTestCase {
    private let recorder = UISegmentRecorder(identifier: UUID())
    private let segment = UISegmentedControl(items: ["first", "second", "third"])
    private var viewAttributes: ViewAttributes = .mockAny()

    func testWhenSegmentIsNotVisible() throws {
        // When
        viewAttributes = .mock(fixture: .invisible)

        // Then
        let semantics = try XCTUnwrap(recorder.semantics(of: segment, with: viewAttributes, in: .mockAny()))
        XCTAssertTrue(semantics is InvisibleElement)
    }

    func testWhenSegmentIsVisible() throws {
        // Given
        segment.selectedSegmentIndex = 2
        if #available(iOS 13.0, *) {
            segment.selectedSegmentTintColor = .mockRandom()
        }

        // When
        viewAttributes = .mock(fixture: .visible(.someAppearance))

        // Then
        let semantics = try XCTUnwrap(recorder.semantics(of: segment, with: viewAttributes, in: .mockAny()))
        XCTAssertTrue(semantics is SpecificElement)
        XCTAssertEqual(semantics.subtreeStrategy, .ignore)

        let builder = try XCTUnwrap(semantics.nodes.first?.wireframesBuilder as? UISegmentWireframesBuilder)
        XCTAssertEqual(builder.attributes, viewAttributes)
        XCTAssertEqual(builder.segmentTitles, ["first", "second", "third"])
        XCTAssertEqual(builder.selectedSegmentIndex, 2)
        if #available(iOS 13.0, *) {
            XCTAssertEqual(builder.selectedSegmentTintColor, segment.selectedSegmentTintColor)
        }
    }

    func testWhenViewIsNotOfExpectedType() {
        // When
        let view = UITextField()

        // Then
        XCTAssertNil(recorder.semantics(of: view, with: viewAttributes, in: .mockAny()))
    }

    func testWhenSegmentHasTextPrivacyOverride() throws {
        // Given
        viewAttributes = .mock(fixture: .visible())
        viewAttributes.textAndInputPrivacy = .maskAll

        // When
        let semantics = try XCTUnwrap(recorder.semantics(of: segment, with: viewAttributes, in: .mockAny()) as? SpecificElement)

        // Then
        let builder = try XCTUnwrap(semantics.nodes.first?.wireframesBuilder as? UISegmentWireframesBuilder)
        XCTAssertTrue(builder.textObfuscator is FixLengthMaskObfuscator)
    }
}
#endif
