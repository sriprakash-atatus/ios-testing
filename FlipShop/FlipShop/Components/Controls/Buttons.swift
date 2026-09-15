/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

/// The app's main call to action. Shows a spinner while `isLoading`, and dims when disabled.
struct PrimaryButton: View {
    enum Style {
        /// Brand blue.
        case filled
        /// Orange — "Buy Now", "Place Order".
        case deal
        /// Yellow — "Add to Cart" beside "Buy Now".
        case accent
        /// Blue outline.
        case outlined
        /// Light blue fill.
        case tinted
        case destructive
    }

    let title: String
    var systemImage: String?
    var style: Style
    var isLoading: Bool
    var isFullWidth: Bool
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(
        _ title: String,
        systemImage: String? = nil,
        style: Style = .filled,
        isLoading: Bool = false,
        isFullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack(spacing: Theme.Spacing.xs) {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                    }
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(textColor)
                }
            }
            .font(.headline)
            .foregroundStyle(textColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, isFullWidth ? Theme.Spacing.md : Theme.Spacing.xl)
            .frame(height: Theme.Size.buttonHeight)
            .background(fillColor, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .overlay {
                if style == .outlined {
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .strokeBorder(Color.brand, lineWidth: 1.5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(ScaleButtonStyle())
        .allowsHitTesting(!isLoading)
        .accessibilityLabel(title)
    }

    private var fillColor: Color {
        switch style {
        case .filled: return .brand
        case .deal: return .deal
        case .accent: return .brandAccent
        case .outlined: return .clear
        case .tinted: return Color.brand.opacity(0.12)
        case .destructive: return Color.danger.opacity(0.12)
        }
    }

    private var textColor: Color {
        switch style {
        case .filled, .deal: return .white
        case .accent: return .black
        case .outlined, .tinted: return .brand
        case .destructive: return .danger
        }
    }
}

/// A round icon button, optionally with a count badge — for toolbars and headers.
struct IconButton: View {
    let systemImage: String
    var badge: Int = 0
    var accessibilityLabel: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .frame(width: Theme.Size.iconButton, height: Theme.Size.iconButton)
                .background(Color.surface, in: Circle())
                .overlay(alignment: .topTrailing) {
                    if badge > 0 {
                        Text(badge > 99 ? "99+" : "\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.danger, in: Capsule())
                            .offset(x: 4, y: -4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.9))
        .accessibilityLabel(accessibilityLabel.isEmpty ? systemImage : accessibilityLabel)
        .animation(Theme.quickSpring, value: badge)
    }
}

/// − 1 + stepper. When the range starts at 0, the minus becomes a trash can at 1.
struct QuantitySelector: View {
    enum Size {
        case compact
        case regular
    }

    @Binding var quantity: Int
    var range: ClosedRange<Int> = 1...Product.maximumOrderQuantity
    var size: Size = .regular

    var body: some View {
        HStack(spacing: 0) {
            step(
                systemImage: range.lowerBound == 0 && quantity <= 1 ? "trash" : "minus",
                isEnabled: quantity > range.lowerBound,
                label: "Decrease quantity"
            ) {
                quantity -= 1
            }

            Text("\(quantity)")
                .font((size == .compact ? Font.subheadline : Font.body).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(size == .compact ? Color.white : Color.textPrimary)
                .frame(minWidth: size == .compact ? 22 : 34)
                .contentTransition(.numericText())
                .accessibilityLabel("Quantity \(quantity)")

            step(systemImage: "plus", isEnabled: quantity < range.upperBound, label: "Increase quantity") {
                quantity += 1
            }
        }
        .frame(height: size == .compact ? Theme.Size.compactButtonHeight : 40)
        .background {
            if size == .compact {
                RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous).fill(Color.brand)
            } else {
                RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous).strokeBorder(Color.divider, lineWidth: 1)
            }
        }
        .sensoryFeedback(.selection, trigger: quantity)
    }

    private func step(systemImage: String, isEnabled: Bool, label: String, change: @escaping () -> Void) -> some View {
        Button {
            withAnimation(Theme.quickSpring) {
                change()
            }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: size == .compact ? 12 : 14, weight: .bold))
                .foregroundStyle(size == .compact ? Color.white : Color.brand)
                .frame(width: size == .compact ? 30 : 40, height: size == .compact ? Theme.Size.compactButtonHeight : 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}

/// A selectable pill for filters and quick options.
struct FilterChip: View {
    let title: String
    var systemImage: String?
    var isSelected: Bool
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                }
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.brand : Color.textPrimary)
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: 34)
            .background(isSelected ? Color.brand.opacity(0.12) : Color.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? Color.brand : Color.divider.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A small coloured label, like "Assured" or "Only 3 left".
struct TagView: View {
    let text: String
    var systemImage: String?
    var color: Color = .brand

    init(_ text: String, systemImage: String? = nil, color: Color = .brand) {
        self.text = text
        self.systemImage = systemImage
        self.color = color
    }

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
