/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

// MARK: - Categories

/// A category's symbol on a soft tile of its colour.
struct CategoryIcon: View {
    let category: ProductCategory
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(category.tint)
            .frame(width: size, height: size)
            .background(category.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// A category with its product count: a square tile for grids and strips, or a full-width row.
struct CategoryCard: View {
    enum Style {
        case tile
        case row
    }

    let category: ProductCategory
    let productCount: Int
    var style: Style = .tile

    var body: some View {
        switch style {
        case .tile:
            VStack(spacing: Theme.Spacing.xs) {
                CategoryIcon(category: category, size: 60)
                VStack(spacing: 2) {
                    Text(category.name)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(productCount) items")
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.xxs)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .subtleShadow()
            .accessibilityElement(children: .combine)
        case .row:
            HStack(spacing: Theme.Spacing.md) {
                CategoryIcon(category: category, size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Text("\(productCount) products")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
            }
            .cardStyle(padding: Theme.Spacing.sm)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Image gallery

/// Swipeable product photos with page dots. Tapping a photo opens it full screen with pinch to zoom.
struct ProductImageCarousel: View {
    let product: Product
    var height: CGFloat = 340

    @State private var selection = 0
    @State private var isShowingViewer = false

    private var images: [URL] {
        product.images.isEmpty ? product.thumbnail.map { [$0] } ?? [] : product.images
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            TabView(selection: $selection) {
                if images.isEmpty {
                    ProductImageView(product: product, padding: Theme.Spacing.xl)
                        .tag(0)
                } else {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, url in
                        ProductImageView(product: product, url: url, padding: Theme.Spacing.xl)
                            .tag(index)
                            .onTapGesture {
                                isShowingViewer = true
                            }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: height)
            .background(Color.imageWell)

            if images.count > 1 {
                HStack(spacing: 6) {
                    ForEach(images.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == selection ? Color.brand : Color.divider)
                            .frame(width: index == selection ? 18 : 6, height: 6)
                    }
                }
                .animation(Theme.quickSpring, value: selection)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Photo \(selection + 1) of \(images.count)")
            }
        }
        .fullScreenCover(isPresented: $isShowingViewer) {
            ImageZoomViewer(product: product, images: images, selection: $selection)
        }
    }
}

/// Full-screen photos with pinch and double-tap zoom.
private struct ImageZoomViewer: View {
    let product: Product
    let images: [URL]
    @Binding var selection: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, url in
                    ZoomableImage(url: url, symbol: product.symbolName)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding()
            .accessibilityLabel("Close")
        }
    }
}

private struct ZoomableImage: View {
    let url: URL
    let symbol: String

    @State private var scale: CGFloat = 1
    @State private var committedScale: CGFloat = 1

    var body: some View {
        RemoteImage(url: url, contentMode: .fit, fallbackSymbol: symbol)
            .background(Color.white)
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = min(max(committedScale * value, 1), 4)
                    }
                    .onEnded { _ in
                        committedScale = scale
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(Theme.spring) {
                    scale = scale > 1 ? 1 : 2.5
                    committedScale = scale
                }
            }
            .padding(.vertical, 60)
    }
}

// MARK: - Search bar

/// The search field: magnifying glass, clear button and an optional Cancel.
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search for products, brands and more"
    /// Focuses the field when it appears.
    var focusOnAppear: Bool = false
    var onSubmit: () -> Void = {}
    /// Shows a Cancel button while editing when set.
    var onCancel: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.textSecondary)

                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !text.isEmpty {
                    Button {
                        text = ""
                        isFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: 44)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .strokeBorder(isFocused ? Color.brand : Color.divider.opacity(0.6), lineWidth: 1)
            )

            if let onCancel = onCancel, isFocused || !text.isEmpty {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                    onCancel()
                }
                .foregroundStyle(Color.brand)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(Theme.quickSpring, value: isFocused)
        .task {
            guard focusOnAppear else {
                return
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
            isFocused = true
        }
    }
}

/// Looks like the search bar; tapping it opens search.
struct SearchLauncher: View {
    var placeholder: String = "Search for products, brands and more"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.textSecondary)
                Text(placeholder)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "mic.fill")
                    .foregroundStyle(Color.brand)
            }
            .font(.subheadline)
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: 44)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .strokeBorder(Color.divider.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.99))
        .accessibilityLabel("Search")
    }
}
