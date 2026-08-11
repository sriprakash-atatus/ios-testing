/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

public class DataStoreMock: DataStore {
    @ReadWriteLock
    public var storage: [String: DataStoreValueResult]

    public init(storage: [String: DataStoreValueResult] = [:]) {
        self.storage = storage
    }

    public func setValue(_ value: Data, forKey key: String, version: DataStoreKeyVersion) {
        storage[key] = .value(value, version)
    }

    public func value(forKey key: String, callback: @escaping (DataStoreValueResult) -> Void) {
        callback(storage[key] ?? .noValue)
    }

    public func removeValue(forKey key: String) {
        storage[key] = nil
    }

    public func clearAllData() {
        storage.removeAll()
    }

    public func flush() {
        // no-op
    }

    // MARK: - Side Effects Observation

    public func value(forKey key: String) -> DataStoreValueResult? {
        return storage[key]
    }
}
