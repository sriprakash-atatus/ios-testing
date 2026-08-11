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

class ATSwiftUIRUMActionsPredicateTests: XCTestCase {
    func testGivenPredicateWithLegacyEnabled_onAnyiOSVersion_itReturnsAction() {
        // Given
        let predicate = objc_DefaultSwiftUIRUMActionsPredicate(isLegacyDetectionEnabled: true)

        // When
        let rumAction = predicate.rumAction(with: "SwiftUI_Action")

        // Then
        XCTAssertEqual(rumAction?.name, "SwiftUI_Action")
        XCTAssertTrue(rumAction!.attributes.isEmpty)
    }

    func testGivenPredicateWithLegacyDisabled_oniOS17_itReturnsNoAction() {
        // Given
        let predicate = objc_DefaultSwiftUIRUMActionsPredicate(isLegacyDetectionEnabled: false)

        // When
        let rumAction = predicate.rumAction(with: "SwiftUI_Action")

        // Then
        if #available(iOS 18.0, *) {
            XCTAssertEqual(rumAction?.name, "SwiftUI_Action")
            XCTAssertTrue(rumAction!.attributes.isEmpty)
        } else {
            XCTAssertNil(rumAction, "On iOS 17 and below with legacy disabled, should return `nil`")
        }
    }
}

#endif
