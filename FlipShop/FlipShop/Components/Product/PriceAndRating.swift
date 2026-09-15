/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

// MARK: - Price

/// Selling price, MRP struck through and the discount — "₹2,499  ₹5,999  58% off".
struct PriceView: View {
    enum Size {
        case small
        case medium
        case large
    }

    let price: Double
    let originalPrice: Double
    let discount: Int
    var size: Size = .medium

    init(price: Double, originalPrice: Double, discount: Int, size: Size = .medium) {
        self.price = price
        self.originalPrice = originalPrice
        self.discount = discount
        self.size = size
    }

    init(product: Product, size: Size = .medium) {
        self.init(price: product.price, originalPrice: product.originalPrice, discount: product.discount, size: size)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size == .large ? Theme.Spacing.xs : 5) {
            Text(Formatters.currency(price))
                .font(priceFont)
                .foregroundStyle(Color.textPrimary)

            if originalPrice > price {
                Text(Formatters.currency(originalPrice))
                    .font(secondaryFont)
                    .strikethrough()
                    .foregroundStyle(Color.textTertiary)

                Text("\(discount)% off")
                    .font(secondaryFont.weight(.semibold))
                    .foregroundStyle(Color.success)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var priceFont: Font {
        switch size {
        case .small: return .priceSmall
        case .medium: return .priceMedium
        case .large: return .priceLarge
        }
    }

    private var secondaryFont: Font {
        switch size {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .subheadline
        }
    }

    private var accessibilityText: String {
        guard originalPrice > price else {
            return Formatters.currency(price)
        }
        return "\(Formatters.currency(price)), was \(Formatters.currency(originalPrice)), \(discount) percent off"
    }
}

/// The orange "28% OFF" tag on product images.
struct DiscountBadge: View {
    let percent: Int

    var body: some View {
        Text("\(percent)% OFF")
            .font(.caption2.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.deal, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

// MARK: - Rating

/// The green "4.3 ★" pill.
struct RatingBadge: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            Text(Formatters.rating(rating))
            Image(systemName: "star.fill")
                .font(.system(size: 8, weight: .bold))
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(tint, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rated \(Formatters.rating(rating)) out of 5")
    }

    private var tint: Color {
        switch rating {
        case 4...: return .ratingGreen
        case 3..<4: return Color(light: 0x7CB342, dark: 0x8BC34A)
        default: return .deal
        }
    }
}

/// A rating with its count: a badge and "(17.6K)" when compact, stars and "17,663 ratings" otherwise.
struct RatingView: View {
    enum Style {
        case compact
        case regular
    }

    let rating: Double
    let reviewCount: Int
    var style: Style = .compact

    var body: some View {
        switch style {
        case .compact:
            HStack(spacing: 4) {
                RatingBadge(rating: rating)
                Text("(\(Formatters.compact(reviewCount)))")
                    .font(.caption2)
                    .foregroundStyle(Color.textSecondary)
            }
        case .regular:
            HStack(spacing: 6) {
                RatingBadge(rating: rating)
                StarRatingView(rating: rating, size: 12)
                Text("\(Formatters.decimal(reviewCount)) ratings")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}

/// Five stars, with halves.
struct StarRatingView: View {
    let rating: Double
    var size: CGFloat = 12
    var color: Color = .brandAccent

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: symbol(for: star))
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(color)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Formatters.rating(rating)) out of 5 stars")
    }

    private func symbol(for star: Int) -> String {
        let value = rating - Double(star - 1)
        if value >= 0.75 {
            return "star.fill"
        }
        return value >= 0.25 ? "star.leadinghalf.filled" : "star"
    }
}

/// Tappable stars for writing a review.
struct StarRatingPicker: View {
    @Binding var rating: Int
    var size: CGFloat = 32

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    withAnimation(Theme.quickSpring) {
                        rating = star
                    }
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: size))
                        .foregroundStyle(star <= rating ? Color.brandAccent : Color.textTertiary)
                        .symbolEffect(.bounce, value: rating == star)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
            }
        }
        .sensoryFeedback(.selection, trigger: rating)
    }
}
