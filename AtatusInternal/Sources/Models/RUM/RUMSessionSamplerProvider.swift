/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

/// Provides the RUM session deterministic sampler for the active session.
public protocol RUMSessionSamplerProvider {
    /// The RUM session deterministic sampler for the active session. `nil` if there is no active session.
    var rumSessionSampler: DeterministicSampler? { get }
}

public extension AtatusFeature where Self: RUMSessionSamplerProvider { }
