/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

/// A product in a grid or rail: photo with discount and heart, name, short description, rating,
/// price and an add-to-cart button. Tapping it opens the product.
///
/// Use inside a `NavigationStack` whose destinations include `Route` (`.routeDestinations()`).
struct ProductCard: View {
    let product: Product
    /// Fixed width for horizontal rails; `nil` fills the grid column.
    var width: CGFloat?

    init(product: Product, width: CGFloat? = nil) {
        self.product = product
        self.width = width
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            NavigationLink(value: Route.product(id: product.id)) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    image
                    details
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))

            AddToCartButton(product: product, style: .compact)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.bottom, Theme.Spacing.xs)
        }
        .frame(width: width)
        .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        // Outside the link, so the heart's tap never opens the product.
        .overlay(alignment: .topTrailing) {
            WishlistButton(product: product, style: .overlay)
                .padding(6)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .subtleShadow()
        .accessibilityElement(children: .contain)
    }

    private var image: some View {
        ProductImageView(product: product)
            .frame(height: Theme.Size.productCardImageHeight)
            .overlay(alignment: .topLeading) {
                if product.hasDiscount {
                    DiscountBadge(percent: product.discount)
                        .padding(Theme.Spacing.xs)
                }
            }
            .overlay(alignment: .bottom) {
                if !product.isInStock {
                    Text("Out of stock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                }
            }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(product.brand.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            Text(product.shortDescription)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)

            RatingView(rating: product.rating, reviewCount: product.reviewCount, style: .compact)
                .padding(.top, 1)

            PriceView(product: product, size: .small)
        }
        .padding(.horizontal, Theme.Spacing.xs)
    }
}

/// A product in a list: photo beside the details, with the heart and add-to-cart on the right.
struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            NavigationLink(value: Route.product(id: product.id)) {
                ProductImageView(product: product)
                    .frame(width: Theme.Size.listRowImage, height: Theme.Size.listRowImage)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if product.hasDiscount {
                            DiscountBadge(percent: product.discount)
                                .scaleEffect(0.85, anchor: .topLeading)
                                .padding(4)
                        }
                    }
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                NavigationLink(value: Route.product(id: product.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.brand.uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                        Text(product.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        RatingView(rating: product.rating, reviewCount: product.reviewCount, style: .compact)
                        PriceView(product: product, size: .medium)
                        availability
                    }
                    // Leaves room for the heart in the corner.
                    .padding(.trailing, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                HStack {
                    Spacer(minLength: 0)
                    AddToCartButton(product: product, style: .compact)
                        .frame(width: 124)
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .overlay(alignment: .topTrailing) {
            WishlistButton(product: product, style: .plain)
                .padding(2)
        }
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .subtleShadow()
    }

    @ViewBuilder
    private var availability: some View {
        switch product.availability {
        case .inStock:
            Text(product.price >= DeliveryOption.freeDeliveryThreshold ? "Free delivery" : "Delivery ₹40")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        case .lowStock:
            Text(product.availability.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deal)
        case .outOfStock:
            Text(product.availability.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.danger)
        }
    }
}

// MARK: - Skeletons

/// A grey rounded block that shimmers — the building brick of loading states.
struct SkeletonBlock: View {
    var width: CGFloat?
    var height: CGFloat
    var radius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.surfaceMuted)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
            .shimmer()
    }
}

struct ProductCardSkeleton: View {
    var width: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            SkeletonBlock(height: Theme.Size.productCardImageHeight, radius: 0)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonBlock(width: 50, height: 8)
                SkeletonBlock(height: 12)
                SkeletonBlock(width: 90, height: 12)
                SkeletonBlock(width: 60, height: 14)
                SkeletonBlock(height: Theme.Size.compactButtonHeight)
            }
            .padding([.horizontal, .bottom], Theme.Spacing.xs)
        }
        .frame(width: width)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .accessibilityLabel("Loading")
    }
}

struct ProductRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            SkeletonBlock(width: Theme.Size.listRowImage, height: Theme.Size.listRowImage, radius: Theme.Radius.sm)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBlock(width: 60, height: 8)
                SkeletonBlock(height: 12)
                SkeletonBlock(width: 120, height: 12)
                SkeletonBlock(width: 80, height: 14)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .accessibilityLabel("Loading")
    }
}
