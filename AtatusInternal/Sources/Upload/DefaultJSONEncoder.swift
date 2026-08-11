/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

extension JSONEncoder: AtatusExtended { }

extension AtatusExtension where ExtendedType == JSONEncoder {
    public static func `default`() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatted = iso8601DateFormatter.string(from: date)
            try container.encode(formatted)
        }
        if #available(iOS 13, tvOS 13, *) {
            encoder.outputFormatting = [.withoutEscapingSlashes]
        }
        return encoder
    }
}
