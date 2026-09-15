/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

struct User: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var name: String
    var email: String
    /// Ten digits, without the country code.
    var phone: String
    let memberSince: Date
    var isPlusMember: Bool

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    /// Up to two initials, for the avatar.
    var initials: String {
        let letters = name.split(separator: " ").prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}

enum AddressType: String, CaseIterable, Identifiable, Codable, Sendable {
    case home
    case work
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .home: return "house.fill"
        case .work: return "briefcase.fill"
        case .other: return "mappin.circle.fill"
        }
    }
}

struct Address: Identifiable, Hashable, Codable, Sendable {
    var id: String
    var fullName: String
    var phone: String
    /// House or flat number and building.
    var line1: String
    /// Area and street.
    var line2: String
    var landmark: String
    var city: String
    var state: String
    var pincode: String
    var type: AddressType
    var isDefault: Bool

    init(
        id: String = UUID().uuidString,
        fullName: String = "",
        phone: String = "",
        line1: String = "",
        line2: String = "",
        landmark: String = "",
        city: String = "",
        state: String = "",
        pincode: String = "",
        type: AddressType = .home,
        isDefault: Bool = false
    ) {
        self.id = id
        self.fullName = fullName
        self.phone = phone
        self.line1 = line1
        self.line2 = line2
        self.landmark = landmark
        self.city = city
        self.state = state
        self.pincode = pincode
        self.type = type
        self.isDefault = isDefault
    }

    /// "42, Prestige Tower, MG Road, Bengaluru, Karnataka 560001".
    var singleLine: String {
        [line1, line2, landmark.isEmpty ? nil : "Near \(landmark)", city, "\(state) \(pincode)"]
            .compactMap { $0 }
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: ", ")
    }

    /// "Bengaluru, Karnataka – 560001".
    var cityLine: String { "\(city), \(state) – \(pincode)" }

    static let indianStates = [
        "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Delhi", "Goa", "Gujarat", "Haryana",
        "Himachal Pradesh", "Jammu and Kashmir", "Jharkhand", "Karnataka", "Kerala", "Ladakh", "Madhya Pradesh",
        "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Puducherry", "Punjab", "Rajasthan",
        "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
    ]
}

struct NotificationPreferences: Hashable, Codable, Sendable {
    var orderUpdates = true
    var offersAndDeals = true
    var priceDrops = true
    var wishlistReminders = false
    var newsletter = false
}

enum AppearancePreference: String, CaseIterable, Identifiable, Codable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var symbolName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
