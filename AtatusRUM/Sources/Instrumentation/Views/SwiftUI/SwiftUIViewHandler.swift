/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

/// Publisher generating RUM Commands on `SwiftUI.View` events.
internal protocol SwiftUIViewHandler: RUMCommandPublisher {
    /// Respond to a `SwiftUI.View.onAppear` event.
    func notify_onAppear(identity: String, name: String, path: String, attributes: [AttributeKey: AttributeValue])

    /// Respond to a `SwiftUI.View.onDisappear` event.
    func notify_onDisappear(identity: String)
}
