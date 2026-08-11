/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddSessionReplay` -> `AtatusSessionReplay`; rebranded the licence header.

#if os(iOS)
import AtatusInternal
import TestUtilities
import XCTest
@testable import AtatusSessionReplay

@available(iOS 13.0, tvOS 13.0, *)
class ImagePrivacyTests: XCTestCase {
    func testShouldRecordImagePredicate() {
        // Given
        let smallImage = MockCGImage.mockWith(width: 20)
        let smallGraphicsImage = GraphicsImage(contents: .cgImage(smallImage), scale: 1.0, orientation: .up, maskColor: nil)

        // Then
        XCTAssertTrue(ImagePrivacyLevel.maskNone.shouldRecordGraphicsImagePredicate(smallGraphicsImage))
        XCTAssertFalse(ImagePrivacyLevel.maskAll.shouldRecordGraphicsImagePredicate(smallGraphicsImage))
        XCTAssertTrue(ImagePrivacyLevel.maskNonBundledOnly.shouldRecordGraphicsImagePredicate(smallGraphicsImage))

        // Given
        let largeImage = MockCGImage.mockWith(width: 150)
        let largeGraphicsImage = GraphicsImage(contents: .cgImage(largeImage), scale: 1.0, orientation: .up, maskColor: nil)

        // Then
        XCTAssertTrue(ImagePrivacyLevel.maskNone.shouldRecordGraphicsImagePredicate(largeGraphicsImage))
        XCTAssertFalse(ImagePrivacyLevel.maskAll.shouldRecordGraphicsImagePredicate(largeGraphicsImage))
        XCTAssertFalse(ImagePrivacyLevel.maskNonBundledOnly.shouldRecordGraphicsImagePredicate(largeGraphicsImage))
    }
}
#endif
