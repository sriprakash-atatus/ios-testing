/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation
import AtatusInternal

extension ATError: AnyMockable, RandomMockable {
    public static func mockAny() -> ATError {
        return ATError(
            type: .mockAny(),
            message: .mockAny(),
            stack: .mockAny()
        )
    }

    public static func mockRandom() -> ATError {
        return ATError(
            type: .mockRandom(),
            message: .mockRandom(),
            stack: .mockRandom()
        )
    }
}
