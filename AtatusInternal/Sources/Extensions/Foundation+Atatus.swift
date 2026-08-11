/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

extension Thread: AtatusExtended {}
extension AtatusExtension where ExtendedType: Thread {
    /// Returns the name of current thread if available or the nature of thread otherwise: `"main" | "background"`.
    public var name: String {
        if let name = Thread.current.name, !name.isEmpty {
            return name
        }

        return Thread.isMainThread ? "main" : "background"
    }
}
