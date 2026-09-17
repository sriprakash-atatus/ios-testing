/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(AccountStore.self) private var account
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.brand)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.user?.name ?? "FlipShop Shopper")
                            .font(.headline)
                        Text(session.user?.email ?? "guest@flipshop.io")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Section("My Activity") {
                NavigationLink(value: Route.orders) {
                    Label("My Orders", systemImage: "shippingbox")
                }
                NavigationLink(value: Route.wishlist) {
                    Label("Wishlist", systemImage: "heart")
                }
            }

            Section("Account Settings") {
                NavigationLink(value: Route.editProfile) {
                    Label("Edit Profile", systemImage: "person")
                }
                NavigationLink(value: Route.addresses) {
                    Label("Addresses", systemImage: "mappin.and.ellipse")
                }
                NavigationLink(value: Route.paymentMethods) {
                    Label("Saved Cards & UPI", systemImage: "creditcard")
                }
                NavigationLink(value: Route.notifications) {
                    Label("Notifications", systemImage: "bell")
                }
            }

            Section("App") {
                NavigationLink(value: Route.settings) {
                    Label("Settings", systemImage: "gearshape")
                }
                NavigationLink(value: Route.helpSupport) {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
                NavigationLink(value: Route.about) {
                    Label("About FlipShop", systemImage: "info.circle")
                }
            }

            Section {
                if session.isSignedIn {
                    Button(role: .destructive) {
                        Task {
                            await session.logout()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                } else {
                    Button {
                        router.present(.auth)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign In")
                                .foregroundStyle(Color.brand)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Profile")
    }
}

struct EditProfileView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var phone: String = ""

    var body: some View {
        Form {
            Section("Personal Details") {
                TextField("Full Name", text: $name)
                TextField("Phone Number", text: $phone)
                    .keyboardType(.phonePad)
            }
            Button("Save Changes") {
                dismiss()
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            name = session.user?.name ?? ""
            phone = session.user?.phone ?? ""
        }
    }
}

struct AddressesView: View {
    @Environment(AccountStore.self) private var account

    var body: some View {
        List {
            ForEach(account.addresses) { address in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(address.fullName)
                            .fontWeight(.semibold)
                        Spacer()
                        if address.isDefault {
                            Text("DEFAULT")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brand.opacity(0.15))
                                .foregroundStyle(Color.brand)
                                .cornerRadius(4)
                        }
                    }
                    Text(address.singleLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Phone: \(address.phone)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Saved Addresses")
    }
}

struct PaymentMethodsView: View {
    @Environment(AccountStore.self) private var account

    var body: some View {
        List {
            Section("Saved Cards") {
                if account.cards.isEmpty {
                    Text("No saved cards").foregroundStyle(.secondary)
                } else {
                    ForEach(account.cards) { card in
                        HStack(spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .font(.title2)
                                .foregroundStyle(Color.brand)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(card.holderName)
                                    .fontWeight(.medium)
                                Text("•••• \(card.last4)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Saved UPI IDs") {
                if account.upiIDs.isEmpty {
                    Text("No saved UPI IDs").foregroundStyle(.secondary)
                } else {
                    ForEach(account.upiIDs) { upi in
                        HStack(spacing: 12) {
                            Image(systemName: "qrcode")
                                .font(.title2)
                                .foregroundStyle(Color.brand)
                            Text(upi.handle)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .navigationTitle("Payment Methods")
    }
}

struct NotificationSettingsView: View {
    @State private var orderUpdates = true
    @State private var promotions = false
    @State private var priceDrops = true

    var body: some View {
        Form {
            Toggle("Order & Delivery Updates", isOn: $orderUpdates)
            Toggle("Exclusive Offers & Promotions", isOn: $promotions)
            Toggle("Price Drop Alerts", isOn: $priceDrops)
        }
        .navigationTitle("Notifications")
    }
}

struct SettingsView: View {
    @State private var darkMode = false

    var body: some View {
        Form {
            Section("Preferences") {
                Toggle("Appearance (Dark Mode)", isOn: $darkMode)
            }
            Section("Version") {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("1.0.0 (Build 1)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct HelpSupportView: View {
    var body: some View {
        List {
            Section("FAQs") {
                Text("How do I track my delivery?")
                Text("What is the return policy?")
                Text("How do refunds work?")
            }
            Section("Contact Us") {
                Label("support@flipshop.io", systemImage: "envelope")
                Label("1800-123-4567", systemImage: "phone")
            }
        }
        .navigationTitle("Help & Support")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.brand)
            Text("FlipShop")
                .font(.title)
                .fontWeight(.bold)
            Text("Modern Swift 6 & iOS e-commerce showcase application instrumented with Atatus Mobile APM & Session Replay.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.top, 48)
        .navigationTitle("About")
    }
}

struct OrdersView: View {
    @Environment(OrderStore.self) private var orders

    var body: some View {
        Group {
            if orders.orders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("No orders placed yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("When you buy products, your orders will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(orders.orders) { order in
                        NavigationLink(value: Route.orderDetail(orderID: order.id)) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Order #\(order.id.prefix(8))")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text(order.status.title)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.brand.opacity(0.12))
                                        .foregroundStyle(Color.brand)
                                        .cornerRadius(4)
                                }
                                Text("\(order.items.count) items • \(order.pricing.total.formattedCurrency)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("My Orders")
    }
}

struct OrderDetailView: View {
    let orderID: String
    @Environment(OrderStore.self) private var orders

    var body: some View {
        if let order = orders.order(id: orderID) {
            List {
                Section("Order Information") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(order.status.title)
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Order Date")
                        Spacer()
                        Text(order.placedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                Section("Items") {
                    ForEach(order.items) { line in
                        HStack {
                            Text(line.product.name)
                            Spacer()
                            Text("\(line.quantity) x \(line.unitPrice.formattedCurrency)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Tracking") {
                    NavigationLink(value: Route.orderTracking(orderID: orderID)) {
                        Label("Track Shipment", systemImage: "location")
                    }
                }
            }
            .navigationTitle("Order #\(orderID.prefix(8))")
        } else {
            Text("Order not found")
        }
    }
}

struct OrderTrackingView: View {
    let orderID: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "truck.box.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.brand)
            Text("Package in Transit")
                .font(.title2)
                .fontWeight(.bold)
            Text("Estimated delivery in 2 business days.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 48)
        .navigationTitle("Track Shipment")
    }
}
