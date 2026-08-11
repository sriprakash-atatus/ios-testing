/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation
import CommonCrypto

internal protocol Hashing {
    func hash(from data: Data) -> String
}

internal struct SHA1Hashing: Hashing {
    func hash(from data: Data) -> String {
        var digest: [UInt8] = Array(repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { CC_SHA1($0.baseAddress, UInt32(data.count), &digest) }
        return digest
            .map { String(format: "%02hhx", $0) }
            .joined(separator: "")
    }
}
