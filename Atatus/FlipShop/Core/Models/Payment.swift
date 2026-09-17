/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

// Payments are simulated end to end. Nothing here holds a full card number or a CVV: a saved card
// keeps its brand, last four digits and expiry, which is all the UI shows.

enum PaymentMethodKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case card
    case applePay
    case upi
    case cashOnDelivery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .card: return "Credit / Debit Card"
        case .applePay: return "Apple Pay"
        case .upi: return "UPI"
        case .cashOnDelivery: return "Cash on Delivery"
        }
    }

    var subtitle: String {
        switch self {
        case .card: return "Visa, Mastercard, RuPay and Amex"
        case .applePay: return "Pay with Face ID or Touch ID"
        case .upi: return "Google Pay, PhonePe, Paytm and more"
        case .cashOnDelivery: return "Pay in cash or UPI when it arrives"
        }
    }

    var symbolName: String {
        switch self {
        case .card: return "creditcard.fill"
        case .applePay: return "apple.logo"
        case .upi: return "indianrupeesign.circle.fill"
        case .cashOnDelivery: return "banknote.fill"
        }
    }
}

enum CardBrand: String, CaseIterable, Codable, Sendable {
    case visa
    case mastercard
    case rupay
    case amex
    case unknown

    var title: String {
        switch self {
        case .visa: return "Visa"
        case .mastercard: return "Mastercard"
        case .rupay: return "RuPay"
        case .amex: return "American Express"
        case .unknown: return "Card"
        }
    }

    /// Recognises the brand from the leading digits of a card number.
    static func detect(fromNumber number: String) -> CardBrand {
        let digits = number.filter(\.isNumber)
        if digits.hasPrefix("4") {
            return .visa
        }
        if digits.hasPrefix("34") || digits.hasPrefix("37") {
            return .amex
        }
        if digits.hasPrefix("60") || digits.hasPrefix("65") || digits.hasPrefix("81") || digits.hasPrefix("82") || digits.hasPrefix("508") {
            return .rupay
        }
        if let prefix = Int(digits.prefix(2)), (51...55).contains(prefix) {
            return .mastercard
        }
        if let prefix = Int(digits.prefix(4)), (2221...2720).contains(prefix) {
            return .mastercard
        }
        return .unknown
    }
}

struct SavedCard: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let brand: CardBrand
    let last4: String
    let holderName: String
    let expiryMonth: Int
    /// Four digits.
    let expiryYear: Int
    var nickname: String

    var maskedNumber: String { "•••• \(last4)" }
    var expiryText: String { String(format: "%02d/%02d", expiryMonth, expiryYear % 100) }

    func isExpired(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let year = components.year, let month = components.month else {
            return false
        }
        return expiryYear < year || (expiryYear == year && expiryMonth < month)
    }
}

struct SavedUPI: Identifiable, Hashable, Codable, Sendable {
    let id: String
    /// e.g. `priya@okhdfcbank`.
    let handle: String
}

/// The payment the shopper chose at checkout.
enum PaymentSelection: Hashable, Codable, Sendable {
    case card(SavedCard)
    case applePay
    case upi(handle: String)
    case cashOnDelivery

    /// Orders above this value cannot be paid on delivery.
    static let cashOnDeliveryLimit: Double = 50_000

    var kind: PaymentMethodKind {
        switch self {
        case .card: return .card
        case .applePay: return .applePay
        case .upi: return .upi
        case .cashOnDelivery: return .cashOnDelivery
        }
    }

    var title: String {
        switch self {
        case .card(let card): return "\(card.brand.title) \(card.maskedNumber)"
        case .applePay: return "Apple Pay"
        case .upi(let handle): return "UPI · \(handle)"
        case .cashOnDelivery: return "Cash on Delivery"
        }
    }

    var symbolName: String { kind.symbolName }

    /// Cash on delivery is collected at the door; everything else is authorised before the order is placed.
    var requiresAuthorization: Bool { kind != .cashOnDelivery }

    /// "Paid via UPI · priya@okhdfcbank", or "Pay on delivery".
    var summary: String {
        requiresAuthorization ? "Paid via \(title)" : "Pay on delivery"
    }
}

struct PaymentReceipt: Hashable, Codable, Sendable {
    let transactionID: String
    let amount: Double
    let method: PaymentMethodKind
    let authorizedAt: Date
}
