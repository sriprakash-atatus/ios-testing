/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import AtatusInternal

extension AccountConfigurationContext: AnyMockable, RandomMockable {
    public static func mockAny() -> Self { mockWith() }

    public static func mockRandom() -> Self {
        .init(
            id: .mockRandom(),
            name: .mockRandom()
        )
    }

    public static func mockWith(
        id: String = .mockAny(),
        name: String? = .mockAny()
    ) -> Self {
        .init(
            id: id,
            name: name
        )
    }
}
