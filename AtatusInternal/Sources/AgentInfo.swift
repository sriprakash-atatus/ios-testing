/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

// ATCHG: New file, porting `AgentInfo` from the Atatus Android agent
// (`atatus-sdk-android-core/src/main/kotlin/com/atatus/android/AgentInfo.kt`).
//
// The agent name and version are reported to the Atatus backend on every upload, both as
// request headers/query parameters and as an `agent` object inside each event payload.
// Cross-platform agents (Flutter, React Native) overwrite `agentName` so the backend can
// attribute events to the wrapping SDK rather than the native one.
/// Identifies the agent sending data to Atatus.
public enum AgentInfo {
    /// The name of the agent, e.g. `"Atatus iOS Agent"`.
    ///
    /// Cross-platform agents override this value with their own name.
    @ReadWriteLock
    public static var agentName: String = "Atatus iOS Agent"

    /// The version of the agent.
    @ReadWriteLock
    public static var agentVersion: String = "1.0.0"

    /// The `agent` object appended to event payloads: `{ "name": ..., "version": ... }`.
    public struct Payload: Encodable {
        public let name: String
        public let version: String

        public init(name: String = AgentInfo.agentName, version: String = AgentInfo.agentVersion) {
            self.name = name
            self.version = version
        }
    }

    /// The `log_source` reported for logs produced by this agent.
    ///
    /// Resolves to the wrapping cross-platform agent when one is set, otherwise to the native
    /// source. Mirrors the `log_source` injection in Android's `LogEventSerializer`, where the
    /// native value is `"kotlin"`.
    public static var logSource: String {
        let name = agentName
        if name.range(of: "Flutter", options: .caseInsensitive) != nil {
            return "flutter"
        }
        if name.range(of: "React Native", options: .caseInsensitive) != nil {
            return "react-native"
        }
        return nativeLogSource
    }

    /// The `log_source` value for the native iOS agent.
    public static let nativeLogSource = "swift"
}

/// Wraps an event and appends the `agent` object to its JSON payload.
///
/// The wrapped value is encoded into the *same* keyed container, so `agent` is merged as a
/// sibling of the event's own properties rather than nested — matching
/// `jsonObject.add("agent", agentObject)` in Android's `RumEventSerializer`, `LogEventSerializer`
/// and `SpanEventSerializer`.
public struct AgentTaggedEvent<Wrapped: Encodable>: Encodable {
    private enum CodingKeys: String, CodingKey {
        case agent
        case logSource = "log_source"
    }

    private let wrapped: Wrapped
    private let logSource: String?

    public init(_ wrapped: Wrapped, logSource: String? = nil) {
        self.wrapped = wrapped
        self.logSource = logSource
    }

    public func encode(to encoder: Encoder) throws {
        try wrapped.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(AgentInfo.Payload(), forKey: .agent)
        try container.encodeIfPresent(logSource, forKey: .logSource)
    }
}

extension Encodable {
    /// Appends the `agent` object (name, version) to this event's JSON payload.
    ///
    /// - Parameter logSource: When set, also appends a `log_source` property. Used by the Logs
    ///   feature to identify whether the log originated from the native or a cross-platform agent.
    public func withAgentInfo(logSource: String? = nil) -> AgentTaggedEvent<Self> {
        AgentTaggedEvent(self, logSource: logSource)
    }
}
// ATCHG: End
