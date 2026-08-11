/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Retries given `block` several `times` in predefined `delay` until it does not throw an error.
/// If all tries resulted with error, the last `Error` is thrown from this function.
internal func retry<R>(times: UInt, delay: TimeInterval, block: () throws -> R) throws -> R {
    for _ in (1..<times) {
        do {
            return try block()
        } catch {
            Thread.sleep(forTimeInterval: delay)
        }
    }

    return try block()
}
