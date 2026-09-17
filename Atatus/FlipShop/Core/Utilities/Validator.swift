/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

enum PasswordStrength: Int, Comparable, Sendable {
    case weak
    case fair
    case strong

    var title: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .strong: return "Strong"
        }
    }

    static func < (lhs: PasswordStrength, rhs: PasswordStrength) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Input checks shared by every form in the app.
enum Validator {
    static func digits(in text: String) -> String {
        text.filter(\.isNumber)
    }

    static func isValidEmail(_ email: String) -> Bool {
        matches(email.trimmingCharacters(in: .whitespaces), pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
    }

    /// Ten digits starting 6–9, as Indian mobile numbers do.
    static func isValidPhone(_ phone: String) -> Bool {
        matches(digits(in: phone), pattern: "^[6-9][0-9]{9}$")
    }

    /// Six digits, not starting with 0.
    static func isValidPincode(_ pincode: String) -> Bool {
        matches(pincode, pattern: "^[1-9][0-9]{5}$")
    }

    static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.allSatisfy { $0.isLetter || $0 == " " || $0 == "." || $0 == "'" }
    }

    static func isValidOTP(_ code: String) -> Bool {
        matches(code, pattern: "^[0-9]{6}$")
    }

    /// At least eight characters with a letter and a digit.
    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 8 && password.contains(where: \.isLetter) && password.contains(where: \.isNumber)
    }

    static func passwordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.contains(where: \.isUppercase) && password.contains(where: \.isLowercase) { score += 1 }
        if password.contains(where: \.isNumber) { score += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 1 }
        switch score {
        case ..<3: return .weak
        case 3...4: return .fair
        default: return .strong
        }
    }

    /// `name@bank`, as UPI handles are written.
    static func isValidUPI(_ handle: String) -> Bool {
        matches(handle.trimmingCharacters(in: .whitespaces), pattern: "^[A-Za-z0-9._-]{2,256}@[A-Za-z]{2,64}$")
    }

    /// 13 to 19 digits passing the Luhn check.
    static func isValidCardNumber(_ number: String) -> Bool {
        let digits = digits(in: number)
        guard (13...19).contains(digits.count) else {
            return false
        }
        var sum = 0
        for (index, character) in digits.reversed().enumerated() {
            guard var value = character.wholeNumberValue else {
                return false
            }
            if index % 2 == 1 {
                value *= 2
                if value > 9 {
                    value -= 9
                }
            }
            sum += value
        }
        return sum % 10 == 0
    }

    /// A month and four-digit year that have not passed.
    static func isValidExpiry(month: Int, year: Int, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard (1...12).contains(month) else {
            return false
        }
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let currentYear = components.year, let currentMonth = components.month else {
            return false
        }
        if year > currentYear + 20 {
            return false
        }
        return year > currentYear || (year == currentYear && month >= currentMonth)
    }

    /// Parses "MM/YY" into a month and four-digit year.
    static func parseExpiry(_ text: String) -> (month: Int, year: Int)? {
        let digits = digits(in: text)
        guard digits.count == 4, let month = Int(digits.prefix(2)), let shortYear = Int(digits.suffix(2)) else {
            return nil
        }
        return (month, 2000 + shortYear)
    }

    static func isValidCVV(_ cvv: String, brand: CardBrand) -> Bool {
        matches(cvv, pattern: brand == .amex ? "^[0-9]{4}$" : "^[0-9]{3}$")
    }

    /// "4242 4242 4242 4242" — groups of four, at most 19 digits.
    static func formattedCardNumber(_ text: String) -> String {
        let digits = String(digits(in: text).prefix(19))
        return stride(from: 0, to: digits.count, by: 4).map { start -> String in
            let startIndex = digits.index(digits.startIndex, offsetBy: start)
            let endIndex = digits.index(startIndex, offsetBy: min(4, digits.count - start))
            return String(digits[startIndex..<endIndex])
        }
        .joined(separator: " ")
    }

    /// "08/29" as the shopper types "0829".
    static func formattedExpiry(_ text: String) -> String {
        let digits = String(digits(in: text).prefix(4))
        guard digits.count > 2 else {
            return digits
        }
        return "\(digits.prefix(2))/\(digits.dropFirst(2))"
    }

    private static func matches(_ text: String, pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}
