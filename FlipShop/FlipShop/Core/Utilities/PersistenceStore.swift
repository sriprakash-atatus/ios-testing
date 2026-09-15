/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

/// Keeps app state — cart, wishlist, orders, session — as JSON files in Application Support, so it
/// survives relaunches. Failures are swallowed: losing a cached cart must never crash the app.
struct PersistenceStore: Sendable {
    enum Key: String, CaseIterable, Sendable {
        case session
        case cart
        case savedForLater
        case appliedCoupon
        case wishlist
        case orders
        case recentSearches
        case addresses
        case cards
        case upiIDs
        case notificationPreferences
        case appearance
    }

    static let shared = PersistenceStore()

    private let directory: URL

    init(directory: URL? = nil) {
        if let directory = directory {
            self.directory = directory
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.directory = base.appendingPathComponent("FlipShop", isDirectory: true)
        }
    }

    func save<Value: Encodable>(_ value: Value, for key: Key) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder.api.encode(value)
            try data.write(to: url(for: key), options: [.atomic])
        } catch {
            // A failed write only loses the cache; the in-memory state is still correct.
        }
    }

    func load<Value: Decodable>(_ type: Value.Type, for key: Key) -> Value? {
        guard let data = try? Data(contentsOf: url(for: key)) else {
            return nil
        }
        return try? JSONDecoder.api.decode(Value.self, from: data)
    }

    func remove(_ key: Key) {
        try? FileManager.default.removeItem(at: url(for: key))
    }

    /// Clears everything tied to an account — not the device-level preferences.
    func removeAccountData() {
        [Key.session, .orders, .addresses, .cards, .upiIDs, .notificationPreferences].forEach(remove)
    }

    private func url(for key: Key) -> URL {
        directory.appendingPathComponent("\(key.rawValue).json")
    }
}
