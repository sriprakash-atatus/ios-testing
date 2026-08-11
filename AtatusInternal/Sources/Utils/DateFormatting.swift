/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

public protocol DateFormatterType: Sendable {
    func string(from date: Date) -> String
    func date(from string: String) -> Date?
}

extension ISO8601DateFormatter: DateFormatterType, @unchecked Sendable {}
extension DateFormatter: DateFormatterType, @unchecked Sendable {}

/// Date formatter producing `ISO8601` string representation of a given date.
/// Should be used to encode dates in messages send to the server.
public let iso8601DateFormatter: DateFormatterType = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions.insert(.withFractionalSeconds)
    return formatter
}()

/// Date formatter producing string representation of a given date for user-facing features (like console output).
public func presentationDateFormatter(withTimeZone timeZone: TimeZone = .current) -> DateFormatterType {
    let formatter = DateFormatter()
    formatter.timeZone = timeZone
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}
