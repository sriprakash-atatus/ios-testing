/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

#if !os(watchOS)

import Foundation
import UIKit
import AtatusInternal

internal final class LegacySwiftUIComponentDetector: SwiftUIComponentDetector {
    func createActionCommand(
        from touch: UITouch,
        predicate: SwiftUIRUMActionsPredicate?,
        dateProvider: DateProvider
    ) -> RUMAddUserActionCommand? {
        guard let predicate,
              touch.phase == .ended else {
            return nil
        }

        if let view = touch.view,
           view.isSwiftUIView,
           // For iOS 17 and below, we can't reliably distinguish SwiftUI component types (e.g., Button vs Label).
           // We exclude hosting views and track other SwiftUI elements with a generic name.
           !SwiftUIContainerViews.shouldIgnore(view.typeDescription) {
            let refinedName = SwiftUIComponentHelpers.extractComponentName(
                touch: touch,
                defaultName: SwiftUIComponentNames.unidentified
            )

            if let rumAction = predicate.rumAction(with: refinedName) {
                return RUMAddUserActionCommand(
                    time: dateProvider.now,
                    attributes: rumAction.attributes,
                    instrumentation: .swiftuiAutomatic,
                    actionType: .tap,
                    name: rumAction.name
                )
            }
        }

        return nil
    }
}

private enum SwiftUIContainerViews {
    /// SwiftUI container views that should be ignored for action tracking
    /// to avoid duplicate events and noise
    static let ignoredTypeDescriptions: Set<String> = [
        "HostingView",
        "HostingScrollView",
        "PlatformGroupContainer"
    ]

    static func shouldIgnore(_ typeDescription: String) -> Bool {
        return ignoredTypeDescriptions.contains { typeDescription.contains($0) }
    }
}

#endif
