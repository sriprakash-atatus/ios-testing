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

class ATSwiftUIRUMViewsPredicateTests: XCTestCase {
    func testGivenDefaultPredicate_whenAskingForExtractedViewName_itReturnsView() {
        // Given
        let predicate = objc_DefaultSwiftUIRUMViewsPredicate()

        // When
        let rumView = predicate.rumView(for: "SwiftUIView")

        // Then
        XCTAssertEqual(rumView?.name, "SwiftUIView")
        XCTAssertTrue(rumView!.attributes.isEmpty)
    }
}

#endif
