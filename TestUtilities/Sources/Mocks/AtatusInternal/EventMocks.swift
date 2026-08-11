/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

extension Event: AnyMockable {
    public static func mockAny() -> Self {
        return mockWith()
    }

    public static func mockWith(data: Data = .init(), metadata: Data? = nil) -> Self {
        return Event(data: data, metadata: metadata)
    }
}
