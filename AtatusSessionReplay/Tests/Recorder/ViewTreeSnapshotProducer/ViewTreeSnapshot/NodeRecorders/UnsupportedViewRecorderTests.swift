/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddSessionReplay` -> `AtatusSessionReplay`; rebranded the licence header.

import XCTest
#if os(iOS)
import WebKit
import SwiftUI
import SafariServices
@_spi(Internal)
import TestUtilities
@_spi(Internal)
@testable import AtatusSessionReplay
@testable import AtatusInternal

@available(iOS 13.0, *)
class UnsupportedViewRecorderTests: XCTestCase {
    func testWhenViewIsUnsupportedViewControllersRootView() throws {
        let recorder = UnsupportedViewRecorder(identifier: UUID(), featureFlags: .defaults)

        var context = ViewTreeRecordingContext.mockRandom()
        context.viewControllerContext.isRootView = true
        context.viewControllerContext.parentType = [.safari, .activity, .swiftUI].randomElement()

        let semantics = try XCTUnwrap(recorder.semantics(of: UIView(), with: .mock(fixture: .visible(.someAppearance)), in: context))
        XCTAssertTrue(semantics is SpecificElement)
        XCTAssertEqual(semantics.subtreeStrategy, .ignore)
        let wireframeBuilder = try XCTUnwrap(semantics.nodes.first?.wireframesBuilder as? UnsupportedViewWireframesBuilder)
        XCTAssertNotNil(wireframeBuilder.unsupportedClassName)
    }

    func testWhenSwiftUIFeatureFlagIsDisabled() throws {
        let recorder = UnsupportedViewRecorder(identifier: UUID(), featureFlags: [.swiftui: false])

        var context = ViewTreeRecordingContext.mockRandom()
        context.viewControllerContext.isRootView = true
        context.viewControllerContext.parentType = .swiftUI

        let semantics = try XCTUnwrap(recorder.semantics(of: UIView(), with: .mock(fixture: .visible(.someAppearance)), in: context))
        XCTAssertTrue(semantics is SpecificElement)
        XCTAssertEqual(semantics.subtreeStrategy, .ignore)
        let builder = try XCTUnwrap(semantics.nodes.first?.wireframesBuilder as? UnsupportedViewWireframesBuilder)
        let wireframes = builder.buildWireframes(with: WireframesBuilder())
        XCTAssertEqual(wireframes.count, 1)
        let wireframe = try XCTUnwrap(wireframes.last?.placeholderWireframe)
        XCTAssertEqual(wireframe.label, "SwiftUI")
    }

    func testWhenSwiftUIFeatureFlagIsEnabled() throws {
        let recorder = UnsupportedViewRecorder(identifier: UUID(), featureFlags: [.swiftui: true])

        var context = ViewTreeRecordingContext.mockRandom()
        context.viewControllerContext.isRootView = true
        context.viewControllerContext.parentType = .swiftUI

        let semantics = recorder.semantics(of: UIView(), with: .mock(fixture: .visible(.someAppearance)), in: context)
        XCTAssertNil(semantics)
    }
}
#endif
