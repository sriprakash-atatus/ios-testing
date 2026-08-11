/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddSessionReplay` -> `AtatusSessionReplay`; rebranded the licence header.

#if os(iOS)
import XCTest
import AtatusInternal
import CoreGraphics
import SwiftUI
@testable import AtatusSessionReplay

@available(iOS 13.0, tvOS 13.0, *)
class ColorReflectionTests: XCTestCase {
    func testColorResolvedReflection() throws {
        let color: SwiftUI.Color._Resolved = .mockRandom()
        let reflector = Reflector(subject: color, telemetry: NOPTelemetry())
        let reflectedColor = try SwiftUI.Color._Resolved(from: reflector)

        XCTAssertEqual(reflectedColor.linearRed, color.linearRed)
        XCTAssertEqual(reflectedColor.linearGreen, color.linearGreen)
        XCTAssertEqual(reflectedColor.linearBlue, color.linearBlue)
        XCTAssertEqual(reflectedColor.opacity, color.opacity)
    }

    func testResolvedPaintReflection() throws {
        if #available(iOS 26, tvOS 26, *) {
            throw XCTSkip("This test uses a test fixture that doesn't match iOS 26's internal structure")
        }

        let color: SwiftUI.Color._Resolved = .mockRandom()
        let paint = ResolvedPaint(paint: color)

        let reflector = Reflector(subject: paint, telemetry: NOPTelemetry())
        let reflectedPaint = try ResolvedPaint(from: reflector)

        XCTAssertNotNil(reflectedPaint.paint)
        XCTAssertEqual(reflectedPaint.paint?.linearRed, color.linearRed)
        XCTAssertEqual(reflectedPaint.paint?.linearGreen, color.linearGreen)
        XCTAssertEqual(reflectedPaint.paint?.linearBlue, color.linearBlue)
        XCTAssertEqual(reflectedPaint.paint?.opacity, color.opacity)
    }

    func testResolvedPaintReflection_withNilPaint() throws {
        let resolvedPaint = ResolvedPaint(paint: nil)

        let reflector = Reflector(subject: resolvedPaint, telemetry: NOPTelemetry())
        let reflectedPaint = try ResolvedPaint(from: reflector)

        XCTAssertNil(reflectedPaint.paint)
    }
}
#endif
