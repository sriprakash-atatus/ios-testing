/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct ProductListingView: View {
    let context: ProductListContext
    @Environment(CatalogStore.self) private var catalog

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let products = catalog.products(for: context.source)

        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(products) { product in
                    ProductCard(product: product)
                }
            }
            .padding()
        }
        .navigationTitle(context.title)
    }
}

struct ProductDetailView: View {
    let productID: String
    @Environment(CatalogStore.self) private var catalog
    @Environment(CartStore.self) private var cart
    @Environment(WishlistStore.self) private var wishlist
    @Environment(AppRouter.self) private var router

    var body: some View {
        if let product = catalog.product(id: productID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ProductImageView(product: product)
                        .frame(height: 320)
                        .cornerRadius(12)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(product.brand)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            WishlistButton(product: product, style: .plain)
                        }

                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 8) {
                            RatingView(rating: product.rating, reviewCount: product.reviewCount)
                            NavigationLink(value: Route.productReviews(productID: product.id)) {
                                Text("See Reviews")
                                    .font(.caption)
                                    .foregroundStyle(Color.brand)
                            }
                        }

                        PriceView(product: product, size: .large)

                        Divider()

                        Text("Description")
                            .font(.headline)

                        Text(product.description)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Divider()

                        HStack(spacing: 12) {
                            PrimaryButton("Add to Cart", style: .accent) {
                                _ = cart.add(product)
                            }
                            PrimaryButton("Buy Now", style: .deal) {
                                let item = CartItem(product: product, quantity: 1, selectedColor: nil, selectedSize: nil)
                                router.present(.checkout(.buyNow(item)))
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle(product.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            Text("Product not found")
        }
    }
}

struct ProductReviewsView: View {
    let productID: String
    @Environment(CatalogStore.self) private var catalog

    var body: some View {
        if let product = catalog.product(id: productID) {
            List {
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        Text(String(format: "%.1f", product.rating))
                            .font(.system(size: 48, weight: .bold))
                        RatingView(rating: product.rating, reviewCount: product.reviewCount)
                        Text("Based on \(product.reviewCount) reviews")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Recent Reviews") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Verified Customer")
                                .fontWeight(.semibold)
                            Spacer()
                            RatingBadge(rating: 5.0)
                        }
                        Text("Great product! Exceeded expectations and fast shipping.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Happy Buyer")
                                .fontWeight(.semibold)
                            Spacer()
                            RatingBadge(rating: 4.5)
                        }
                        Text("Quality is very nice, totally worth the price.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Customer Reviews")
        } else {
            Text("Product not found")
        }
    }
}

struct SearchView: View {
    let initialQuery: String?
    @Environment(SearchStore.self) private var search
    @Environment(CatalogStore.self) private var catalog

    @State private var searchText = ""

    var body: some View {
        List {
            if searchText.isEmpty {
                if !search.recentSearches.isEmpty {
                    Section("Recent Searches") {
                        ForEach(search.recentSearches, id: \.self) { item in
                            Button {
                                searchText = item
                            } label: {
                                Label(item, systemImage: "clock")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            } else {
                let filtered = catalog.products.filter {
                    $0.name.localizedCaseInsensitiveContains(searchText) ||
                    $0.brand.localizedCaseInsensitiveContains(searchText) ||
                    $0.description.localizedCaseInsensitiveContains(searchText)
                }

                Section("Results") {
                    ForEach(filtered) { product in
                        NavigationLink(value: Route.product(id: product.id)) {
                            HStack(spacing: 12) {
                                ProductImageView(product: product)
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(6)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(product.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                    Text(product.price.formattedCurrency)
                                        .font(.caption)
                                        .foregroundStyle(Color.brand)
                                }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search products...")
        .navigationTitle("Search")
        .onAppear {
            if let initial = initialQuery {
                searchText = initial
            }
        }
    }
}
