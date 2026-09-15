/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

// Demo payments only. Card details are validated on the device; the number and CVV are dropped the
// moment the card is saved, and only the brand, last four digits and expiry are kept.

/// Adds a card. Present it in a sheet; it has its own navigation bar.
struct AddCardView: View {
    var onSaved: (SavedCard) -> Void

    @Environment(AccountStore.self) private var account
    @Environment(ToastCenter.self) private var toasts
    @Environment(\.dismiss) private var dismiss

    @State private var number = ""
    @State private var holderName = ""
    @State private var expiry = ""
    @State private var cvv = ""
    @State private var nickname = ""
    @State private var showsErrors = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(onSaved: @escaping (SavedCard) -> Void = { _ in }) {
        self.onSaved = onSaved
    }

    private var brand: CardBrand { CardBrand.detect(fromNumber: number) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    CardPreview(number: number, holderName: holderName, expiry: expiry, brand: brand)

                    InfoBanner(
                        message: "Demo mode — nothing is charged and card details never leave your device. Try 4242 4242 4242 4242, or any valid card ending in 0002 to see a declined payment.",
                        systemImage: "lock.shield.fill",
                        tint: .success
                    )

                    FormTextField("Card number", text: $number, prompt: "1234 5678 9012 3456", systemImage: "creditcard",
                                  keyboard: .numberPad, contentType: .creditCardNumber, error: numberError)
                        .onChange(of: number) { _, newValue in
                            let formatted = Validator.formattedCardNumber(newValue)
                            if formatted != newValue {
                                number = formatted
                            }
                        }

                    FormTextField("Name on card", text: $holderName, prompt: "As printed on the card", systemImage: "person",
                                  contentType: .name, autocapitalization: .characters, error: nameError)

                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        FormTextField("Expiry", text: $expiry, prompt: "MM/YY", systemImage: "calendar",
                                      keyboard: .numberPad, characterLimit: 5, error: expiryError)
                            .onChange(of: expiry) { _, newValue in
                                let formatted = Validator.formattedExpiry(newValue)
                                if formatted != newValue {
                                    expiry = formatted
                                }
                            }
                        FormTextField("CVV", text: $cvv, prompt: brand == .amex ? "4 digits" : "3 digits", systemImage: "lock",
                                      keyboard: .numberPad, isSecure: true, characterLimit: brand == .amex ? 4 : 3, error: cvvError)
                    }

                    FormTextField("Nickname (optional)", text: $nickname, prompt: "E.g. Travel card", autocapitalization: .words)

                    if let errorMessage = errorMessage {
                        InfoBanner(message: errorMessage, systemImage: "exclamationmark.triangle.fill", tint: .danger)
                    }
                }
                .padding(Theme.screenPadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .screenBackground()
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton("Save Card", systemImage: "lock.fill", isLoading: isSaving, action: save)
                    .padding(Theme.screenPadding)
                    .background(.bar)
            }
        }
    }

    // MARK: - Validation

    private var numberProblem: String? {
        Validator.isValidCardNumber(number) ? nil : "Enter a valid card number"
    }

    private var nameProblem: String? {
        holderName.trimmingCharacters(in: .whitespaces).count >= 2 ? nil : "Enter the name on the card"
    }

    private var expiryProblem: String? {
        guard let parsed = Validator.parseExpiry(expiry), Validator.isValidExpiry(month: parsed.month, year: parsed.year) else {
            return "Invalid expiry"
        }
        return nil
    }

    private var cvvProblem: String? {
        Validator.isValidCVV(cvv, brand: brand) ? nil : "Invalid CVV"
    }

    // Problems are only shown once the shopper has tried to save.
    private var numberError: String? { showsErrors ? numberProblem : nil }
    private var nameError: String? { showsErrors ? nameProblem : nil }
    private var expiryError: String? { showsErrors ? expiryProblem : nil }
    private var cvvError: String? { showsErrors ? cvvProblem : nil }

    // MARK: - Saving

    private func save() {
        showsErrors = true
        guard numberProblem == nil, nameProblem == nil, expiryProblem == nil, cvvProblem == nil, let parsed = Validator.parseExpiry(expiry) else {
            Haptics.error()
            return
        }
        errorMessage = nil
        isSaving = true
        Task {
            do {
                let card = try await account.addCard(number: number, holderName: holderName, expiryMonth: parsed.month, expiryYear: parsed.year, nickname: nickname)
                // The full number and CVV are not needed any more.
                number = ""
                cvv = ""
                Haptics.success()
                toasts.show("\(card.brand.title) \(card.maskedNumber) saved")
                onSaved(card)
                dismiss()
            } catch {
                Haptics.error()
                errorMessage = APIError.message(for: error)
            }
            isSaving = false
        }
    }
}

/// A card-shaped preview that fills in as the details are typed.
struct CardPreview: View {
    let number: String
    let holderName: String
    let expiry: String
    let brand: CardBrand

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                Image(systemName: "wave.3.right")
                    .font(.title3)
                Spacer()
                Text(brand == .unknown ? "CARD" : brand.title.uppercased())
                    .font(.headline.weight(.heavy))
                    .italic()
            }

            Text(number.isEmpty ? "•••• •••• •••• ••••" : maskedNumber)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CARD HOLDER")
                        .font(.caption2)
                        .opacity(0.7)
                    Text(holderName.isEmpty ? "YOUR NAME" : holderName.uppercased())
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("EXPIRES")
                        .font(.caption2)
                        .opacity(0.7)
                    Text(expiry.isEmpty ? "MM/YY" : expiry)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
        .foregroundStyle(.white)
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
        )
        .shadow(color: gradient[0].opacity(0.35), radius: 14, y: 8)
        .animation(Theme.spring, value: brand)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Card preview")
    }

    /// Only the last four digits are ever drawn; the rest are bullets, grouped in fours.
    private var maskedNumber: String {
        let digits = Array(Validator.digits(in: number).prefix(19))
        let characters: [String] = digits.enumerated().map { index, digit in
            index < digits.count - 4 ? "•" : String(digit)
        }
        return stride(from: 0, to: characters.count, by: 4)
            .map { start in characters[start..<min(start + 4, characters.count)].joined() }
            .joined(separator: " ")
    }

    private var gradient: [Color] {
        switch brand {
        case .visa: return [Color(light: 0x1A3D8F, dark: 0x1A3D8F), Color(light: 0x2874F0, dark: 0x2874F0)]
        case .mastercard: return [Color(light: 0x2B2B2B, dark: 0x2B2B2B), Color(light: 0xC0392B, dark: 0xC0392B)]
        case .rupay: return [Color(light: 0x0B6E4F, dark: 0x0B6E4F), Color(light: 0xF39C12, dark: 0xF39C12)]
        case .amex: return [Color(light: 0x1F6F8B, dark: 0x1F6F8B), Color(light: 0x99C1DE, dark: 0x99C1DE)]
        case .unknown: return [Color(light: 0x434A54, dark: 0x434A54), Color(light: 0x6C7A89, dark: 0x6C7A89)]
        }
    }
}

/// Adds a UPI ID after a simulated verification.
struct AddUPIView: View {
    var onSaved: (SavedUPI) -> Void

    @Environment(AccountStore.self) private var account
    @Environment(ToastCenter.self) private var toasts
    @Environment(\.dismiss) private var dismiss

    @State private var handle = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(onSaved: @escaping (SavedUPI) -> Void = { _ in }) {
        self.onSaved = onSaved
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                FormTextField("UPI ID", text: $handle, prompt: "yourname@bank", systemImage: "at",
                              keyboard: .emailAddress, autocapitalization: .never, error: errorMessage)

                InfoBanner(message: "We'll send a ₹1 verification request that is refunded right away. (Simulated in this demo — use an ID containing “fail” to see a declined UPI payment later.)")

                Spacer()

                PrimaryButton("Verify and Save", systemImage: "checkmark.shield", isLoading: isSaving, action: save)
                    .disabled(handle.isEmpty)
            }
            .padding(Theme.screenPadding)
            .screenBackground()
            .navigationTitle("Add UPI ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        errorMessage = nil
        isSaving = true
        Task {
            do {
                let upi = try await account.addUPI(handle: handle)
                Haptics.success()
                toasts.show("\(upi.handle) verified")
                onSaved(upi)
                dismiss()
            } catch {
                Haptics.error()
                errorMessage = APIError.message(for: error)
            }
            isSaving = false
        }
    }
}
