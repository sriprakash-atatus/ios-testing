/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct CartView: View {
    @Environment(CartStore.self) private var cart
    @Environment(AppRouter.self) private var router

    var body: some View {
        Group {
            if cart.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("Your cart is empty")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Explore products and add items to your cart.")
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
                VStack(spacing: 0) {
                    List {
                        Section {
                            ForEach(cart.items) { item in
                                HStack(spacing: 12) {
                                    ProductImageView(product: item.product)
                                        .frame(width: 72, height: 72)
                                        .cornerRadius(8)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.product.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .lineLimit(2)

                                        PriceView(product: item.product)

                                        HStack {
                                            Button {
                                                cart.decrement(itemID: item.id)
                                            } label: {
                                                Image(systemName: "minus.circle")
                                                    .font(.title3)
                                            }
                                            .buttonStyle(.plain)

                                            Text("\(item.quantity)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .frame(minWidth: 24)

                                            Button {
                                                _ = cart.increment(itemID: item.id)
                                            } label: {
                                                Image(systemName: "plus.circle")
                                                    .font(.title3)
                                            }
                                            .buttonStyle(.plain)

                                            Spacer()

                                            Button(role: .destructive) {
                                                _ = cart.remove(itemID: item.id)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundStyle(.red)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } header: {
                            Text("Items (\(cart.itemCount))")
                        }

                        Section("Order Summary") {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text(cart.breakdown.subtotal.formattedCurrency)
                            }
                            let totalDiscount = cart.breakdown.productDiscount + cart.breakdown.couponDiscount
                            if totalDiscount > 0 {
                                HStack {
                                    Text("Discount")
                                    Spacer()
                                    Text("-\(totalDiscount.formattedCurrency)")
                                        .foregroundStyle(Color.deal)
                                }
                            }
                            HStack {
                                Text("Delivery")
                                Spacer()
                                Text(cart.breakdown.deliveryFee == 0 ? "FREE" : cart.breakdown.deliveryFee.formattedCurrency)
                            }
                            HStack {
                                Text("Total")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(cart.breakdown.total.formattedCurrency)
                                    .fontWeight(.bold)
                                    .font(.headline)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)

                    VStack(spacing: 8) {
                        PrimaryButton("Proceed to Checkout", style: .deal) {
                            router.present(.checkout(.cart))
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
        }
        .navigationTitle("Cart")
    }
}
