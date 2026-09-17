/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

/// Addresses, saved payment methods and preferences for whoever is using the app.
@MainActor
@Observable
final class AccountStore {
    private(set) var addresses: [Address] = []
    private(set) var cards: [SavedCard] = []
    private(set) var upiIDs: [SavedUPI] = []
    private(set) var notificationPreferences = NotificationPreferences()
    private(set) var appearance: AppearancePreference = .system
    private(set) var state: LoadState = .idle

    @ObservationIgnored private let service: any UserServiceProtocol
    @ObservationIgnored private let persistence: PersistenceStore
    /// Whose data is loaded — `""` for a guest — so switching accounts reloads.
    @ObservationIgnored private var loadedAccountID: String?

    init(service: any UserServiceProtocol, persistence: PersistenceStore = .shared) {
        self.service = service
        self.persistence = persistence
        appearance = persistence.load(AppearancePreference.self, for: .appearance) ?? .system
        notificationPreferences = persistence.load(NotificationPreferences.self, for: .notificationPreferences) ?? NotificationPreferences()
    }

    var defaultAddress: Address? {
        addresses.first(where: \.isDefault) ?? addresses.first
    }

    // MARK: - Loading

    /// Loads the account's addresses and payment methods: from the cache when there is one, otherwise
    /// from the service.
    func load(for user: User?) async {
        let accountID = user?.id ?? ""
        guard loadedAccountID != accountID || state != .loaded else {
            return
        }
        loadedAccountID = accountID
        state = .loading

        if let cached = persistence.load([Address].self, for: .addresses) {
            addresses = cached
            cards = persistence.load([SavedCard].self, for: .cards) ?? []
            upiIDs = persistence.load([SavedUPI].self, for: .upiIDs) ?? []
            state = .loaded
            return
        }

        do {
            async let fetchedAddresses = service.fetchAddresses(for: user)
            async let fetchedMethods = service.fetchPaymentMethods(for: user)
            addresses = try await fetchedAddresses
            let methods = try await fetchedMethods
            cards = methods.cards
            upiIDs = methods.upiIDs
            persistAll()
            state = .loaded
        } catch {
            state = .failed(message: APIError.message(for: error))
        }
    }

    // MARK: - Addresses

    /// Adds `address`, or updates the one with its ID. The first address, or one marked default, becomes the default.
    @discardableResult
    func saveAddress(_ address: Address) async throws -> Address {
        var saved = try await service.saveAddress(address)
        if addresses.isEmpty {
            saved.isDefault = true
        }
        if saved.isDefault {
            for index in addresses.indices {
                addresses[index].isDefault = false
            }
        }
        if let index = addresses.firstIndex(where: { $0.id == saved.id }) {
            addresses[index] = saved
        } else {
            addresses.insert(saved, at: 0)
        }
        ensureDefaultAddress()
        persistence.save(addresses, for: .addresses)
        return saved
    }

    func deleteAddress(id: String) async throws {
        try await service.deleteAddress(id: id)
        addresses.removeAll { $0.id == id }
        ensureDefaultAddress()
        persistence.save(addresses, for: .addresses)
    }

    func setDefaultAddress(id: String) {
        for index in addresses.indices {
            addresses[index].isDefault = addresses[index].id == id
        }
        persistence.save(addresses, for: .addresses)
    }

    // MARK: - Payment methods

    /// Saves a card. Only its brand, last four digits and expiry are kept.
    @discardableResult
    func addCard(number: String, holderName: String, expiryMonth: Int, expiryYear: Int, nickname: String) async throws -> SavedCard {
        let card = try await service.addCard(number: number, holderName: holderName, expiryMonth: expiryMonth, expiryYear: expiryYear, nickname: nickname)
        cards.insert(card, at: 0)
        persistence.save(cards, for: .cards)
        return card
    }

    func deleteCard(id: String) async throws {
        try await service.deleteCard(id: id)
        cards.removeAll { $0.id == id }
        persistence.save(cards, for: .cards)
    }

    @discardableResult
    func addUPI(handle: String) async throws -> SavedUPI {
        let upi = try await service.addUPI(handle: handle)
        upiIDs.removeAll { $0.handle == upi.handle }
        upiIDs.insert(upi, at: 0)
        persistence.save(upiIDs, for: .upiIDs)
        return upi
    }

    func deleteUPI(id: String) {
        upiIDs.removeAll { $0.id == id }
        persistence.save(upiIDs, for: .upiIDs)
    }

    // MARK: - Preferences

    func updateNotificationPreferences(_ preferences: NotificationPreferences) async {
        notificationPreferences = preferences
        persistence.save(preferences, for: .notificationPreferences)
        try? await service.updateNotificationPreferences(preferences)
    }

    func setAppearance(_ appearance: AppearancePreference) {
        self.appearance = appearance
        persistence.save(appearance, for: .appearance)
    }

    /// Forgets the account's data on sign-out. Appearance is a device setting and stays.
    func reset() {
        addresses = []
        cards = []
        upiIDs = []
        notificationPreferences = NotificationPreferences()
        loadedAccountID = nil
        state = .idle
        persistence.removeAccountData()
    }

    // MARK: - Private

    private func ensureDefaultAddress() {
        if !addresses.isEmpty && !addresses.contains(where: \.isDefault) {
            addresses[0].isDefault = true
        }
    }

    private func persistAll() {
        persistence.save(addresses, for: .addresses)
        persistence.save(cards, for: .cards)
        persistence.save(upiIDs, for: .upiIDs)
    }
}
