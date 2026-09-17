/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct CategoriesView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(AppRouter.self) private var router

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(catalog.categories) { category in
                    Button {
                        router.push(.productList(.category(category)))
                    } label: {
                        VStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: category.tintHex).opacity(0.15))
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Image(systemName: category.symbolName)
                                        .font(.title)
                                        .foregroundStyle(Color(hex: category.tintHex))
                                )

                            Text(category.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Categories")
        .background(Color(.systemGroupedBackground))
    }
}
