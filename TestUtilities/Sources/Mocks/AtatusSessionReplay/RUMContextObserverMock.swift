/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddSessionReplay` -> `AtatusSessionReplay`; rebranded the licence header.

#if os(iOS)
import Foundation
import AtatusInternal

@testable import AtatusSessionReplay

class RUMContextObserverMock: RUMContextObserver {
    private var queue: Queue?
    private var onNew: ((RUMCoreContext?) -> Void)?

    func observe(on queue: Queue, notify: @escaping (RUMCoreContext?) -> Void) {
        self.queue = queue
        self.onNew = notify
    }

    func notify(rumContext: RUMCoreContext?) {
        queue?.run { self.onNew?(rumContext) }
    }
}
#endif
