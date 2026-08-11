/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `_dd` attribute prefix to `_atatus`; rebranded the licence
// header.

/// The mechanism used to make a span sampling decision.
///
/// The raw values are the ones used in propagation headers like `_atatus.p.dm`. They do not include the `-` character,
/// since that character is a separator and not part of the value itself.
public enum SamplingMechanismType: String, Equatable, Comparable, Sendable {
    /// Fallback mechanism. This mechanism samples all spans. It should never be used, but it's included for completion.
    case fallback = "0"
    /// The main decision mechanism. Although the SDK runs in an agent-less scenario, we consider the SDK sampling
    /// decisions act as the agent rate in scenarios with independent tracers and agent.
    case agentRate = "1"
    /// Decision mechanism used when a decision is manually set by the developer.
    case manual = "4"

    typealias SamplingMechanismPrecedence = Int

    /// Precedence values used to sort sampling mechanisms by order of precedence.
    ///
    /// - Note: We need to explicitly model these values because, per spec, the order of the raw values is actually
    /// different from the precedence order.
    private var precedence: SamplingMechanismPrecedence {
        switch self {
        case .fallback:  0
        case .agentRate: 1
        case .manual:    2
        }
    }

    public static func < (lhs: SamplingMechanismType, rhs: SamplingMechanismType) -> Bool {
        lhs.precedence < rhs.precedence
    }
}
