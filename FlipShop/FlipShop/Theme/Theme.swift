/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI
import UIKit

/// Spacing, corner radii and sizes. Every screen lays out with these so the app reads as one product.
enum Theme {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    enum Radius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }

    enum Size {
        static let buttonHeight: CGFloat = 52
        static let compactButtonHeight: CGFloat = 36
        static let iconButton: CGFloat = 36
        /// Width of a product card in a horizontal rail.
        static let railCardWidth: CGFloat = 164
        static let productCardImageHeight: CGFloat = 150
        static let listRowImage: CGFloat = 96
    }

    /// Side padding of scrolling screens.
    static let screenPadding: CGFloat = 16

    /// Standard spring for state changes like adding to cart.
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let quickSpring = Animation.spring(response: 0.25, dampingFraction: 0.85)
}

// MARK: - Colours

extension Color {
    /// Marketplace blue: headers, links, selected states.
    static let brand = Color(light: 0x2874F0, dark: 0x5B9BFF)
    /// Warm yellow: secondary calls to action, highlights.
    static let brandAccent = Color(light: 0xFFC200, dark: 0xFFD54F)
    /// Orange: "Buy Now", flash sale, urgency.
    static let deal = Color(light: 0xFB641B, dark: 0xFF8A50)
    static let success = Color(light: 0x1E9E4A, dark: 0x3DD27A)
    static let warning = Color(light: 0xE68A00, dark: 0xFFB340)
    static let danger = Color(light: 0xD93025, dark: 0xFF6B60)
    /// Green behind rating badges.
    static let ratingGreen = Color(light: 0x388E3C, dark: 0x2E9E48)

    static let appBackground = Color(uiColor: .systemGroupedBackground)
    /// Cards and grouped rows on `appBackground`.
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    /// Image wells, skeletons and quiet fills.
    static let surfaceMuted = Color(uiColor: .tertiarySystemFill)
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
    static let divider = Color(uiColor: .separator)

    /// A colour that follows light and dark mode.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// A colour from `#RRGGBB`; grey when the string does not parse.
    init(hex: String) {
        self.init(uiColor: UIColor(rgb: UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x8E8E93))
    }
}

extension ShapeStyle where Self == Color {
    static var brand: Color { Color.brand }
    static var brandAccent: Color { Color.brandAccent }
    static var deal: Color { Color.deal }
    static var success: Color { Color.success }
    static var warning: Color { Color.warning }
    static var danger: Color { Color.danger }
    static var ratingGreen: Color { Color.ratingGreen }
    static var appBackground: Color { Color.appBackground }
    static var surface: Color { Color.surface }
    static var surfaceMuted: Color { Color.surfaceMuted }
    static var textPrimary: Color { Color.textPrimary }
    static var textSecondary: Color { Color.textSecondary }
    static var textTertiary: Color { Color.textTertiary }
    static var divider: Color { Color.divider }
}

extension UIColor {
    convenience init(rgb: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Type

extension Font {
    /// Prices on product pages and totals.
    static let priceLarge = Font.system(.title2, design: .rounded).weight(.bold)
    static let priceMedium = Font.system(.headline, design: .rounded).weight(.bold)
    static let priceSmall = Font.system(.subheadline, design: .rounded).weight(.semibold)
    /// Section titles on scrolling screens.
    static let sectionTitle = Font.title3.weight(.bold)
}

// MARK: - Appearance

extension AppearancePreference {
    /// The colour scheme to force, or `nil` to follow the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension ProductCategory {
    var tint: Color { Color(hex: tintHex) }
}

extension ProductColor {
    var color: Color { Color(hex: hex) }
}
