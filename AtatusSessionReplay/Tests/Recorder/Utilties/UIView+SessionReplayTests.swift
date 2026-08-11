/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddSessionReplay` -> `AtatusSessionReplay`; renamed `dd*` types to `Atatus*`; rebranded the
// licence header.

#if os(iOS)
import XCTest
import UIKit
import AtatusInternal
import TestUtilities
@testable import AtatusSessionReplay

class UIViewSessionReplayTests: XCTestCase {
    func testUsesDarkMode() {
        guard #available(iOS 13.0, *) else {
            XCTAssertFalse(UIView().dd.usesDarkMode) // always false prior to iOS 13.x
            return
        }
        class MockView: NSObject, AtatusExtended, UITraitEnvironment {
            var traitCollection: UITraitCollection = .init(userInterfaceStyle: .unspecified)
            func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {}
        }

        // Given
        let lightView = MockView()
        let darkView = MockView()

        // When
        lightView.traitCollection = .init(userInterfaceStyle: [.light, .unspecified].randomElement()!)
        darkView.traitCollection = .init(userInterfaceStyle: .dark)

        // Then
        XCTAssertFalse(lightView.dd.usesDarkMode)
        XCTAssertTrue(darkView.dd.usesDarkMode)
    }

    // swiftlint:disable opening_brace
    func testIsSensitiveText() {
       class Mock: NSObject, AtatusExtended, UITextInputTraits {
            var isSecureTextEntry = false
            var textContentType: UITextContentType! = nil // swiftlint:disable:this implicitly_unwrapped_optional
        }

        // Given
        let sensitiveTextMock = Mock()
        let nonSensitiveTextMock = Mock()
        let nonSensitiveContentTypes = UITextContentType.allCases.subtracting(Mock.dd.sensitiveTypes)

        // When
        oneOrMoreOf([
            { sensitiveTextMock.isSecureTextEntry = true },
            { sensitiveTextMock.textContentType = Mock.dd.sensitiveTypes.randomElement() },
        ])
        oneOrMoreOf([
            { nonSensitiveTextMock.isSecureTextEntry = false },
            { nonSensitiveTextMock.textContentType = nil },
            { nonSensitiveTextMock.textContentType = nonSensitiveContentTypes.randomElement() },
        ])

        // Then
        XCTAssertTrue(sensitiveTextMock.dd.isSensitiveText)
        XCTAssertFalse(nonSensitiveTextMock.dd.isSensitiveText)
    }
    // swiftlint:enable opening_brace
}
#endif
