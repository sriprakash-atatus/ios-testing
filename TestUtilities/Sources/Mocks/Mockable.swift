/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

public protocol AnyMockable {
    static func mockAny() -> Self
}

public protocol RandomMockable {
    static func mockRandom() -> Self
}
