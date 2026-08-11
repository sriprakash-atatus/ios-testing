/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import AtatusInternal
import Foundation

/// Core mock that only allows registering and retrieving features.
///
/// Usage:
///
///     let core = FeatureRegistrationCoreMock()
///     let feature = MyCustomFeature()
///
///     try core.register(feature: feature)
///     
///     core.get(feature: MyCustomFeature.self) === feature // true
///     core.get(feature: OtherFeature.self) // returns nil
///
/// **Note:** If you need different capabilities, check other available core mocks,
/// before you consider adding it here.
public final class FeatureRegistrationCoreMock: AtatusCoreProtocol, Sendable {
    /// Counts references to this mock, so we can test if there are no memory leaks.
    @ReadWriteLock
    public private(set) static var referenceCount = 0

    public internal(set) var registeredFeatures: [AtatusFeature] = []

    public init() {
        Self._referenceCount.mutate { $0 += 1 }
    }

    deinit {
        Self._referenceCount.mutate { $0 -= 1 }
    }

    // MARK: - Supported

    public func register<T>(feature: T) throws where T: AtatusFeature {
        registeredFeatures.append(feature)
    }

    public func feature<T>(named name: String, type: T.Type) -> T? {
        return registeredFeatures.firstElement(of: type)
    }

    // MARK: - Unsupported

    public func scope<T>(for featureType: T.Type) -> FeatureScope where T: AtatusFeature {
        return NOPFeatureScope()
    }

    public func set<Context>(context: @escaping () -> Context?) where Context: AdditionalContext {
        // not supported - use different type of core mock if you need this
    }

    public func send(message: AtatusInternal.FeatureMessage, else fallback: @escaping () -> Void) {
        // not supported - use different type of core mock if you need this
    }

    public func mostRecentModifiedFileAt(before: Date) throws -> Date? {
        return nil
    }
}
