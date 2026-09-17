/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

/// Adds or edits a delivery address. Present it in a sheet; it has its own navigation bar.
struct AddressFormView: View {
    let address: Address?
    var onSaved: (Address) -> Void

    @Environment(AccountStore.self) private var account
    @Environment(SessionStore.self) private var session
    @Environment(ToastCenter.self) private var toasts
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Address
    @State private var showsErrors = false
    @State private var isSaving = false
    @State private var isLocating = false
    @State private var errorMessage: String?

    init(address: Address? = nil, onSaved: @escaping (Address) -> Void = { _ in }) {
        self.address = address
        self.onSaved = onSaved
        _draft = State(initialValue: address ?? Address())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Button(action: useCurrentLocation) {
                        HStack {
                            if isLocating {
                                ProgressView()
                            } else {
                                Image(systemName: "location.fill")
                            }
                            Text(isLocating ? "Finding your location…" : "Use my current location")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundStyle(Color.brand)
                        .padding(Theme.Spacing.sm)
                        .background(Color.brand.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isLocating)

                    section("Contact details") {
                        FormTextField("Full name", text: $draft.fullName, prompt: "Name of the receiver", systemImage: "person",
                                      contentType: .name, autocapitalization: .words, error: error(for: .name))
                        FormTextField("Mobile number", text: $draft.phone, prompt: "10-digit mobile number", systemImage: "phone",
                                      keyboard: .phonePad, contentType: .telephoneNumber, characterLimit: 10, error: error(for: .phone), prefix: "+91")
                    }

                    section("Address") {
                        FormTextField("Pincode", text: $draft.pincode, prompt: "6-digit pincode", systemImage: "mappin.and.ellipse",
                                      keyboard: .numberPad, contentType: .postalCode, characterLimit: 6, error: error(for: .pincode))
                        FormTextField("House no., building", text: $draft.line1, prompt: "Flat, house no., building, company",
                                      contentType: .streetAddressLine1, autocapitalization: .words, error: error(for: .line1))
                        FormTextField("Area, street", text: $draft.line2, prompt: "Area, colony, street, sector",
                                      contentType: .streetAddressLine2, autocapitalization: .words, error: error(for: .line2))
                        FormTextField("Landmark (optional)", text: $draft.landmark, prompt: "E.g. near Apollo Hospital", autocapitalization: .words)
                        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                            FormTextField("City", text: $draft.city, prompt: "City", contentType: .addressCity,
                                          autocapitalization: .words, error: error(for: .city))
                            statePicker
                        }
                    }

                    section("Save address as") {
                        Picker("Address type", selection: $draft.type) {
                            ForEach(AddressType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Make this my default address", isOn: $draft.isDefault)
                            .tint(Color.brand)
                            .font(.subheadline)
                    }

                    if let errorMessage = errorMessage {
                        InfoBanner(message: errorMessage, systemImage: "exclamationmark.triangle.fill", tint: .danger)
                    }
                }
                .padding(Theme.screenPadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .screenBackground()
            .navigationTitle(address == nil ? "Add Address" : "Edit Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton("Save Address", systemImage: "checkmark", isLoading: isSaving, action: save)
                    .padding(Theme.screenPadding)
                    .background(.bar)
            }
            .onAppear(perform: prefillContact)
            .onChange(of: draft.pincode) { _, pincode in
                fillCityAndState(from: pincode)
            }
        }
    }

    // MARK: - Layout

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
            content()
        }
    }

    private var statePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("State")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.textSecondary)
            Menu {
                Picker("State", selection: $draft.state) {
                    ForEach(Address.indianStates, id: \.self) { state in
                        Text(state).tag(state)
                    }
                }
            } label: {
                HStack {
                    Text(draft.state.isEmpty ? "Select" : draft.state)
                        .foregroundStyle(draft.state.isEmpty ? Color.textTertiary : Color.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .frame(height: 50)
                .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .strokeBorder(error(for: .state) == nil ? Color.divider.opacity(0.7) : Color.danger, lineWidth: 1)
                )
            }
            if let stateError = error(for: .state) {
                Text(stateError)
                    .font(.caption)
                    .foregroundStyle(Color.danger)
            }
        }
    }

    // MARK: - Validation

    private enum Field {
        case name, phone, pincode, line1, line2, city, state
    }

    /// The problem shown under `field`, once the shopper has tried to save.
    private func error(for field: Field) -> String? {
        showsErrors ? problem(with: field) : nil
    }

    private func problem(with field: Field) -> String? {
        switch field {
        case .name: return Validator.isValidName(draft.fullName) ? nil : "Enter the receiver's full name"
        case .phone: return Validator.isValidPhone(draft.phone) ? nil : "Enter a valid 10-digit mobile number"
        case .pincode: return Validator.isValidPincode(draft.pincode) ? nil : "Enter a valid 6-digit pincode"
        case .line1: return draft.line1.trimmingCharacters(in: .whitespaces).count >= 3 ? nil : "Enter your house or building"
        case .line2: return draft.line2.trimmingCharacters(in: .whitespaces).count >= 3 ? nil : "Enter the area or street"
        case .city: return draft.city.trimmingCharacters(in: .whitespaces).isEmpty ? "Required" : nil
        case .state: return draft.state.isEmpty ? "Required" : nil
        }
    }

    private var isValid: Bool {
        [Field.name, .phone, .pincode, .line1, .line2, .city, .state].allSatisfy { problem(with: $0) == nil }
    }

    // MARK: - Actions

    private func prefillContact() {
        guard address == nil, draft.fullName.isEmpty, let user = session.user else {
            return
        }
        draft.fullName = user.name
        draft.phone = user.phone
    }

    private func fillCityAndState(from pincode: String) {
        guard pincode.count == 6, let match = PincodeDirectory.lookup(pincode) else {
            return
        }
        if draft.city.isEmpty {
            draft.city = match.city
        }
        if draft.state.isEmpty {
            draft.state = match.state
        }
    }

    /// Simulated location lookup: fills in an address in Bengaluru.
    private func useCurrentLocation() {
        isLocating = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            draft.pincode = "560038"
            draft.line2 = "100 Feet Road, Indiranagar"
            draft.city = "Bengaluru"
            draft.state = "Karnataka"
            isLocating = false
            Haptics.success()
        }
    }

    private func save() {
        showsErrors = true
        guard isValid else {
            Haptics.error()
            return
        }
        errorMessage = nil
        isSaving = true
        Task {
            do {
                let saved = try await account.saveAddress(draft)
                Haptics.success()
                toasts.show(address == nil ? "Address added" : "Address updated")
                onSaved(saved)
                dismiss()
            } catch {
                Haptics.error()
                errorMessage = APIError.message(for: error)
            }
            isSaving = false
        }
    }
}

/// City and state for the first digits of a pincode — enough to autofill the metros.
private enum PincodeDirectory {
    private static let prefixes: [String: (city: String, state: String)] = [
        "11": ("New Delhi", "Delhi"),
        "38": ("Ahmedabad", "Gujarat"),
        "40": ("Mumbai", "Maharashtra"),
        "41": ("Pune", "Maharashtra"),
        "50": ("Hyderabad", "Telangana"),
        "56": ("Bengaluru", "Karnataka"),
        "60": ("Chennai", "Tamil Nadu"),
        "68": ("Kochi", "Kerala"),
        "70": ("Kolkata", "West Bengal"),
        "30": ("Jaipur", "Rajasthan")
    ]

    static func lookup(_ pincode: String) -> (city: String, state: String)? {
        prefixes[String(pincode.prefix(2))]
    }
}
