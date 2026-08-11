/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddRUM` -> `AtatusRUM`; renamed the `DD` symbol
// prefix to `AT`; rebranded the licence header.

#if !os(watchOS)

import XCTest
@_spi(objc)
import AtatusRUM

#if canImport(SwiftUI)
import SwiftUI
#endif

class ATUIKitRUMActionsPredicateTests: XCTestCase {
    func testGivenDefaultPredicate_whenAskingForCustomView_itNamesTheActionByItsClassName() {
        // Given
        let predicate = objc_DefaultUIKitRUMActionsPredicate()

        // When
        #if os(tvOS)
        let rumAction = predicate.rumAction(press: .select, targetView: UIButton())
        #else
        let rumAction = predicate.rumAction(targetView: UIButton())
        #endif
        // Then
        XCTAssertEqual(rumAction?.name, "UIButton")
        XCTAssertTrue(rumAction!.attributes.isEmpty)
    }

    func testGivenDefaultPredicate_whenAskingForViewWithAccesiblityIdentifier_itNamesTheActionWithIt() {
        // Given
        let predicate = objc_DefaultUIKitRUMActionsPredicate()
        let targetView = UIButton()
        targetView.accessibilityIdentifier = "Identifier"

        // When
        #if os(tvOS)
        let rumAction = predicate.rumAction(press: .select, targetView: targetView)
        #else
        let rumAction = predicate.rumAction(targetView: targetView)
        #endif

        // Then
        XCTAssertEqual(rumAction?.name, "UIButton(Identifier)")
        XCTAssertTrue(rumAction!.attributes.isEmpty)
    }

#if canImport(SwiftUI)
    func testGivenDefaultPredicate_whenAskingSwiftUIView_itReturnsAction() {
        guard #available(iOS 13, tvOS 13, *) else {
            return
        }
        // Given
        let predicate = objc_DefaultUIKitRUMActionsPredicate()

        // When
        let swiftUIView = UIHostingController(rootView: EmptyView()).view!
        #if os(tvOS)
        let rumAction = predicate.rumAction(press: .select, targetView: swiftUIView)
        #else
        let rumAction = predicate.rumAction(targetView: swiftUIView)
        #endif

        // Then
        XCTAssertNotNil(rumAction)
    }
#endif
}

#endif
