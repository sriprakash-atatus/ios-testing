/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` members to `at*`; rebranded the licence header.

#if os(iOS)

import Foundation

extension Int64 {
    static func atWithNoOverflow<T: BinaryFloatingPoint>(dimension: T) -> Int64 {
        guard dimension > 0 else {
            return 0
        }

        return Swift.max(1, atWithNoOverflow(dimension))
    }
}

@_spi(Internal)
public extension Int64 {
    static func positiveRandom<T>(using generator: inout T) -> Int64 where T: RandomNumberGenerator {
        .random(in: 0..<Int64.max, using: &generator)
    }
}

#endif
