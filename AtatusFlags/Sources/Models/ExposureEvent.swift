/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

internal struct ExposureEvent: Equatable, Codable {
    struct Identifier: Equatable, Codable {
        let key: String
    }

    struct Subject: Equatable, Codable {
        let id: String
        let attributes: [String: AnyValue]
    }

    let timestamp: Int64
    let allocation: Identifier
    let flag: Identifier
    let variant: Identifier
    let subject: Subject
}
