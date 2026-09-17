/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct AuthFlowView: View {
    let isDismissable: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts

    @State private var email = "alex@example.com"
    @State private var password = "password"
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isDismissable {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.brand)

                    Text("Welcome to FlipShop")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Sign in to sync your cart, wishlist and orders")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    FormTextField(
                        "Email",
                        text: $email,
                        prompt: "Enter email",
                        keyboard: .emailAddress
                    )

                    FormTextField(
                        "Password",
                        text: $password,
                        prompt: "Enter password",
                        isSecure: true
                    )
                }
                .padding(.horizontal)

                PrimaryButton("Sign In", isLoading: isLoading) {
                    Task {
                        isLoading = true
                        defer { isLoading = false }
                        do {
                            try await session.login(email: email, password: password)
                            if isDismissable {
                                dismiss()
                            }
                        } catch {
                            toasts.show(error.localizedDescription, style: .error)
                        }
                    }
                }
                .padding(.horizontal)

                PrimaryButton("Continue as Guest", style: .outlined) {
                    session.continueAsGuest()
                    if isDismissable {
                        dismiss()
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}
