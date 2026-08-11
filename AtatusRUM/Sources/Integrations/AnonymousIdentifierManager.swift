/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

internal protocol AnonymousIdentifierManaging {
    func manageAnonymousIdentifier(shouldTrack: Bool)
}

internal class AnonymousIdentifierManager: AnonymousIdentifierManaging {
    private let featureScope: FeatureScope
    private let uuidGenerator: RUMUUIDGenerator

    init(
        featureScope: FeatureScope,
        uuidGenerator: RUMUUIDGenerator
    ) {
        self.featureScope = featureScope
        self.uuidGenerator = uuidGenerator
    }

    func manageAnonymousIdentifier(shouldTrack: Bool) {
        if shouldTrack {
            featureScope.rumDataStore.value(forKey: .anonymousId) { [weak self] (anonymousId: String?) in
                if let anonymousId {
                    self?.featureScope.set(anonymousId: anonymousId)
                } else {
                    let anonymousId = self?.uuidGenerator.generateUnique().toRUMDataFormat
                    self?.featureScope.rumDataStore.setValue(anonymousId, forKey: .anonymousId)
                    self?.featureScope.set(anonymousId: anonymousId)
                }
            }
        } else {
            featureScope.rumDataStore.removeValue(forKey: .anonymousId)
            featureScope.set(anonymousId: nil)
        }
    }
}
