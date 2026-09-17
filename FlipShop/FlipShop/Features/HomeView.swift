/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct HomeView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(AppRouter.self) private var router

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Search bar header
                Button {
                    router.push(.search(query: nil))
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text("Search for products, brands and more")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                // Banners Carousel
                if !catalog.banners.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(catalog.banners) { banner in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(banner.title)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text(banner.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.85))
                                    Spacer()
                                    Text(banner.ctaTitle)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(.white)
                                        .foregroundStyle(Color.brand)
                                        .cornerRadius(6)
                                }
                                .padding()
                                .frame(width: 280, height: 130, alignment: .leading)
                                .background(Color(hex: banner.backgroundHex))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Categories Quick Rail
                if !catalog.categories.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Top Categories")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(catalog.categories) { category in
                                    Button {
                                        router.push(.productList(.category(category)))
                                    } label: {
                                        VStack(spacing: 6) {
                                            Circle()
                                                .fill(Color(hex: category.tintHex).opacity(0.15))
                                                .frame(width: 56, height: 56)
                                                .overlay(
                                                    Image(systemName: category.symbolName)
                                                        .font(.title3)
                                                        .foregroundStyle(Color(hex: category.tintHex))
                                                )
                                            Text(category.name)
                                                .font(.caption)
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 64)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // Featured Products
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Featured Products")
                            .font(.headline)
                        Spacer()
                        Button("See All") {
                            router.push(.productList(.allProducts))
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.brand)
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(catalog.products) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("FlipShop")
        .refreshable {
            await catalog.refresh()
        }
    }
}
