/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

enum Formatters {
    private static let indiaLocale = Locale(identifier: "en_IN")

    private static func dateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = indiaLocale
        formatter.dateFormat = format
        return formatter
    }

    private static let shortDateFormatter = dateFormatter("EEE, d MMM")
    private static let mediumDateFormatter = dateFormatter("d MMM yyyy")
    private static let dateTimeFormatter = dateFormatter("d MMM, h:mm a")
    private static let timeFormatter = dateFormatter("h:mm a")

    /// "₹1,24,999" — Indian digit grouping, no paise.
    static func currency(_ amount: Double) -> String {
        let rupees = Int(amount.rounded())
        return (rupees < 0 ? "-₹" : "₹") + indianGrouping(abs(rupees))
    }

    /// "17,663", "1,24,999".
    static func decimal(_ value: Int) -> String {
        (value < 0 ? "-" : "") + indianGrouping(abs(value))
    }

    /// Groups digits the Indian way — the last three, then pairs — without depending on the device's
    /// locale data, which formats en_IN differently across platforms.
    private static func indianGrouping(_ value: Int) -> String {
        let digits = String(value)
        guard digits.count > 3 else {
            return digits
        }
        var rest = String(digits.dropLast(3))
        var groups = [String(digits.suffix(3))]
        while rest.count > 2 {
            groups.insert(String(rest.suffix(2)), at: 0)
            rest = String(rest.dropLast(2))
        }
        if !rest.isEmpty {
            groups.insert(rest, at: 0)
        }
        return groups.joined(separator: ",")
    }

    /// "17.6K", "1.2M" — for review and sold counts.
    static func compact(_ value: Int) -> String {
        switch value {
        case ..<1_000:
            return "\(value)"
        case ..<1_000_000:
            return trimmed(Double(value) / 1_000) + "K"
        default:
            return trimmed(Double(value) / 1_000_000) + "M"
        }
    }

    private static func trimmed(_ value: Double) -> String {
        let text = String(format: "%.1f", (value * 10).rounded(.down) / 10)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }

    /// "4.3".
    static func rating(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    /// "Sat, 14 Sep".
    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    /// "14 Sep 2026".
    static func mediumDate(_ date: Date) -> String {
        mediumDateFormatter.string(from: date)
    }

    /// "14 Sep, 3:42 PM".
    static func dateTime(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    /// "3:42 PM".
    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// "Today", "Tomorrow" or "Sat, 14 Sep" — for delivery estimates.
    static func deliveryDay(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return shortDate(date)
    }

    /// "02:14:09" — for sale countdowns. Never negative.
    static func countdown(_ interval: TimeInterval) -> String {
        let total = max(Int(interval), 0)
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    /// "+91 98••• ••210".
    static func maskedPhone(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        guard digits.count >= 10 else {
            return phone
        }
        let tail = digits.suffix(10)
        return "+91 \(tail.prefix(2))••• ••\(tail.suffix(3))"
    }

    /// "pr•••@gmail.com".
    static func maskedEmail(_ email: String) -> String {
        let parts = email.split(separator: "@", maxSplits: 1)
        guard parts.count == 2 else {
            return email
        }
        return "\(parts[0].prefix(2))•••@\(parts[1])"
    }

    /// "+91 98765 43210".
    static func phone(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        guard digits.count == 10 else {
            return phone
        }
        return "+91 \(digits.prefix(5)) \(digits.suffix(5))"
    }
}

extension Double {
    var formattedCurrency: String {
        Formatters.currency(self)
    }
}
