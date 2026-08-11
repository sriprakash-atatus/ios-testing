/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

/// Publishes the current `UserInfo` value to receiver.
internal final class UserInfoPublisher: ContextValuePublisher {
    let initialValue: UserInfo? = .empty

    private var receiver: ContextValueReceiver<UserInfo>?

    var current: UserInfo = .empty {
        didSet { receiver?(current) }
    }

    func publish(to receiver: @escaping ContextValueReceiver<UserInfo?>) {
        self.receiver = receiver
    }

    func cancel() {
        receiver = nil
    }
}
