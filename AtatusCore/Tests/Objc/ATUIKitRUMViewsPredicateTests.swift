/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddRUM` -> `AtatusRUM`; renamed the `DD` symbol
// prefix to `AT`; rebranded the licence header.

#if !os(watchOS)

import XCTest
import TestUtilities
@_spi(objc)
@testable import AtatusRUM

#if canImport(SwiftUI)
import SwiftUI
#endif

class ATUIKitRUMViewsPredicateTests: XCTestCase {
    func testGivenDefaultPredicate_whenAskingForCustomSwiftViewController_itNamesTheViewByItsClassName() {
        // Given
        let predicate = objc_DefaultUIKitRUMViewsPredicate()

        // When
        let customViewController = createMockView(viewControllerClassName: "CustomSwiftViewController")
        let rumView = predicate.rumView(for: customViewController)

        // Then
        XCTAssertEqual(rumView?.name, "CustomSwiftViewController")
        XCTAssertTrue(rumView!.attributes.isEmpty)
    }

    func testGivenDefaultPredicate_whenAskingForCustomObjcViewController_itNamesTheViewByItsClassName() {
        // Given
        let predicate = objc_DefaultUIKitRUMViewsPredicate()

        // When
        let customViewController = CustomObjcViewController()
        let rumView = predicate.rumView(for: customViewController)

        // Then
        XCTAssertEqual(rumView?.name, "CustomObjcViewController")
        XCTAssertTrue(rumView!.attributes.isEmpty)
    }

    func testGivenDefaultPredicate_whenAskingUIKitViewController_itReturnsNoView() {
        // Given
        let predicate = objc_DefaultUIKitRUMViewsPredicate()

        // When
        let uiKitViewController = UIViewController()
        let rumView = predicate.rumView(for: uiKitViewController)

        // Then
        XCTAssertNil(rumView)
    }

#if canImport(SwiftUI)
    func testGivenDefaultPredicate_whenAskingSwiftUIViewController_itReturnsNoView() {
        guard #available(iOS 13, tvOS 13, *) else {
            return
        }
        // Given
        let predicate = objc_DefaultUIKitRUMViewsPredicate()

        // When
        let swiftUIHostingController = UIHostingController<EmptyView>(rootView: EmptyView())
        let rumView = predicate.rumView(for: swiftUIHostingController)

        // Then
        XCTAssertNil(rumView)
    }
#endif
}

#endif
