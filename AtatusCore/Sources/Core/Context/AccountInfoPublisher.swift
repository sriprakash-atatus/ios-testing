/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

/// Publishes the current `AccountInfo` value to receiver.
internal final class AccountInfoPublisher: ContextValuePublisher {
    let initialValue: AccountInfo? = nil

    private var receiver: ContextValueReceiver<AccountInfo?>?

    var current: AccountInfo? = nil {
        didSet { receiver?(current) }
    }

    func publish(to receiver: @escaping ContextValueReceiver<AccountInfo?>) {
        self.receiver = receiver
    }

    func cancel() {
        receiver = nil
    }
}
