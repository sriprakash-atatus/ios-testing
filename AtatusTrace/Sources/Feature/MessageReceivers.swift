/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

internal struct CoreContext {
    /// Provides the history of app foreground / background states.
    var applicationStateHistory: AppStateHistory?

    /// Provides the current active RUM context, if any
    var rumContext: RUMCoreContext?

    /// Provides the current user information, if any
    var userInfo: UserInfo?

    /// Provides the current account information, if any
    var accountInfo: AccountInfo?
}

internal final class ContextMessageReceiver: FeatureMessageReceiver {
    /// Creates a new `ContextMessageReceiver`.
    ///
    /// - parameters:
    ///   - samplerProvider: The sampler provider that will be updated with the RUM
    ///   deterministic tracer.
    init(samplerProvider: SamplerProvider) {
        self.samplerProvider = samplerProvider
        self.context = .init()
    }

    /// The up-to-date core context.
    ///
    /// The context is synchronized using a read-write lock.
    @ReadWriteLock
    var context: CoreContext

    /// The tracer sampler that should be updated with the RUM deterministic sampler.
    let samplerProvider: SamplerProvider

    /// Process messages receives from the bus.
    ///
    /// - Parameters:
    ///   - message: The Feature message
    ///   - core: The core from which the message is transmitted.
    func receive(message: FeatureMessage, from core: AtatusCoreProtocol) -> Bool {
        switch message {
        case .context(let context):
            return update(context: context, from: core)
        default:
            return false
        }
    }

    /// Updates context of the `AtatusTracer` if available.
    ///
    /// - Parameter context: The updated core context.
    private func update(context atatusContext: AtatusContext, from core: AtatusCoreProtocol) -> Bool {
        let rumContext = atatusContext.additionalContext(ofType: RUMCoreContext.self)

        _context.mutate {
            $0.applicationStateHistory = atatusContext.applicationStateHistory
            $0.rumContext = rumContext
            $0.userInfo = atatusContext.userInfo
            $0.accountInfo = atatusContext.accountInfo
        }

        samplerProvider.updateWith(deterministicSampler: rumContext?.sessionSampler)

        return true
    }
}
