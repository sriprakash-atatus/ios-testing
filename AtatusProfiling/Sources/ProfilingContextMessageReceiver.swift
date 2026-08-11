/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import AtatusInternal

internal final class ProfilingContextMessageReceiver: FeatureMessageReceiver {
    let profilingSamplerProvider: ProfilingSamplerProvider

    init(profilingSamplerProvider: ProfilingSamplerProvider) {
        self.profilingSamplerProvider = profilingSamplerProvider
    }

    func receive(message: FeatureMessage, from core: AtatusCoreProtocol) -> Bool {
        guard case let .context(context) = message,
              let deterministicSampler = context.additionalContext(ofType: RUMCoreContext.self)?.sessionSampler else {
            return false
        }

        profilingSamplerProvider.updateWith(deterministicSampler: deterministicSampler)

        return false
    }
}
