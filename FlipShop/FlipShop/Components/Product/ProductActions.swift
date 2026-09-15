/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

/// The heart. Saves or removes the product and says so in a toast.
struct WishlistButton: View {
    enum Style {
        /// On a product image, on a frosted circle.
        case overlay
        /// Bare, for rows and toolbars.
        case plain
    }

    let product: Product
    var style: Style = .overlay

    @Environment(WishlistStore.self) private var wishlist
    @Environment(ToastCenter.self) private var toasts
    @Environment(AppRouter.self) private var router

    private var isSaved: Bool { wishlist.contains(productID: product.id) }

    var body: some View {
        Button(action: toggle) {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.system(size: style == .overlay ? 15 : 19, weight: .semibold))
                .foregroundStyle(isSaved ? Color.danger : (style == .overlay ? Color.textSecondary : Color.textPrimary))
                .symbolEffect(.bounce, value: isSaved)
                .frame(width: style == .overlay ? 32 : 40, height: style == .overlay ? 32 : 40)
                .background {
                    if style == .overlay {
                        Circle().fill(.regularMaterial)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isSaved)
        .accessibilityLabel(isSaved ? "Remove from wishlist" : "Save to wishlist")
    }

    private func toggle() {
        let saved = withAnimation(Theme.quickSpring) {
            wishlist.toggle(product)
        }
        if saved {
            toasts.show("Saved to your wishlist", actionTitle: "View") {
                router.select(.wishlist)
            }
        } else {
            toasts.show("Removed from your wishlist", style: .info)
        }
    }
}

/// Adds a product to the cart from a card or row. Once it's in the cart it turns into a stepper, so
/// the quantity can change without leaving the list. Products with sizes open their page instead,
/// since a size has to be chosen first.
struct AddToCartButton: View {
    enum Style {
        /// A small full-width button at the foot of a card.
        case compact
        /// A regular-height button.
        case regular
    }

    let product: Product
    var style: Style = .compact

    @Environment(CartStore.self) private var cart
    @Environment(ToastCenter.self) private var toasts
    @Environment(AppRouter.self) private var router

    private var needsVariantChoice: Bool { !product.sizes.isEmpty }
    private var itemID: String { CartItem.makeID(productID: product.id, color: product.colors.first?.name, size: nil) }
    private var quantity: Int { cart.item(withID: itemID)?.quantity ?? 0 }
    private var height: CGFloat { style == .compact ? Theme.Size.compactButtonHeight : 44 }

    var body: some View {
        Group {
            if !product.isInStock {
                Button {
                    Haptics.tap()
                    toasts.show("We'll let you know when it's back in stock", style: .info)
                } label: {
                    label("Notify Me", systemImage: "bell", foreground: .textSecondary, background: Color.surfaceMuted)
                }
            } else if quantity > 0 && !needsVariantChoice {
                QuantitySelector(quantity: quantityBinding, range: 0...product.purchasableQuantity, size: .compact)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous))
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else {
                Button(action: add) {
                    label(needsVariantChoice ? "Select \(product.sizeLabel)" : "Add", systemImage: needsVariantChoice ? "slider.horizontal.3" : "plus", foreground: .brand, background: Color.brand.opacity(0.1))
                }
                .transition(.opacity)
            }
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.96))
        .animation(Theme.spring, value: quantity)
    }

    private func label(_ title: String, systemImage: String, foreground: Color, background: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(background, in: RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous))
    }

    private var quantityBinding: Binding<Int> {
        Binding(
            get: { quantity },
            set: { newValue in
                if newValue <= 0 {
                    if let removed = cart.remove(itemID: itemID) {
                        toasts.show("Removed from cart", style: .info, actionTitle: "Undo") {
                            cart.restore(removed)
                        }
                    }
                } else if case .limitReached(let maximum) = cart.setQuantity(newValue, forItemID: itemID) {
                    Haptics.warning()
                    toasts.show("You can buy up to \(maximum) of this item", style: .warning)
                }
            }
        )
    }

    private func add() {
        guard !needsVariantChoice else {
            router.push(.product(id: product.id))
            return
        }
        switch cart.add(product, color: product.colors.first?.name) {
        case .added, .updated:
            Haptics.success()
            toasts.show("Added to cart", actionTitle: "View Cart") {
                router.select(.cart)
            }
        case .limitReached(let maximum):
            Haptics.warning()
            toasts.show("You can buy up to \(maximum) of this item", style: .warning)
        case .outOfStock:
            Haptics.error()
            toasts.show("This item is out of stock", style: .error)
        }
    }
}
