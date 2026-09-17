/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct WishlistView: View {
    @Environment(WishlistStore.self) private var wishlist
    @Environment(AppRouter.self) private var router

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if wishlist.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("Your wishlist is empty")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Explore products and tap the heart icon to save items for later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    PrimaryButton("Start Shopping") {
                        router.select(.home)
                    }
                    .padding(.horizontal, 48)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(wishlist.products) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Wishlist")
    }
}
