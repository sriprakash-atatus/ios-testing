/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct CheckoutFlowView: View {
    let source: CheckoutSource
    @Environment(\.dismiss) private var dismiss
    @Environment(CartStore.self) private var cart
    @Environment(AccountStore.self) private var account
    @Environment(OrderStore.self) private var orders
    @Environment(AppRouter.self) private var router

    @State private var store: CheckoutStore?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Group {
                if let checkout = store {
                    VStack(spacing: 0) {
                        List {
                            Section("Shipping Address") {
                                if let addr = checkout.selectedAddress {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(addr.fullName).fontWeight(.semibold)
                                        Text(addr.singleLine).foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("No address selected")
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Section("Order Summary") {
                                ForEach(checkout.items) { item in
                                    HStack {
                                        Text("\(item.quantity)x \(item.product.name)")
                                            .lineLimit(1)
                                        Spacer()
                                        Text(item.lineTotal.formattedCurrency)
                                    }
                                }
                                HStack {
                                    Text("Total Amount")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text(checkout.breakdown.total.formattedCurrency)
                                        .fontWeight(.bold)
                                }
                            }
                        }

                        VStack(spacing: 8) {
                            PrimaryButton("Place Order", style: .deal, isLoading: isSubmitting) {
                                Task {
                                    isSubmitting = true
                                    checkout.payment = .cashOnDelivery
                                    if let order = await checkout.placeOrder() {
                                        dismiss()
                                        router.present(.orderSuccess(orderID: order.id))
                                    }
                                    isSubmitting = false
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            store = CheckoutStore(
                source: source,
                cart: cart,
                account: account,
                orders: orders,
                payments: MockPaymentService()
            )
        }
    }
}

struct OrderSuccessView: View {
    let orderID: String
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.deal)

            Text("Order Placed Successfully!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Order #\(orderID.prefix(8))\nThank you for shopping with FlipShop!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()

            PrimaryButton("Continue Shopping") {
                dismiss()
                router.select(.home)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
