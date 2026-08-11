/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import AtatusInternal

// ATCHG: New file, porting `AgentHeartbeatScheduler` and `Atatus.setAgentEnabled` from the
// Atatus Android agent (`atatus-sdk-android-core/src/main/kotlin/com/atatus/android/AgentInfo.kt`
// and `Atatus.kt`).
//
// The scheduler polls the agent heartbeat and enables or disables data collection according to
// the backend's answer. It lives in `AtatusCore` because it drives tracking consent.

/// Polls the agent heartbeat and switches data collection on or off accordingly.
public final class AgentHeartbeatScheduler {
    /// The shared scheduler started by `Atatus.initialize`.
    public static let shared = AgentHeartbeatScheduler()

    /// The polling interval, matching the 30 minutes used on Android.
    public static let pollingInterval: TimeInterval = 30 * 60

    @ReadWriteLock
    private var isRunning = false

    private let queue = DispatchQueue(label: "com.atatus.agent-heartbeat", qos: .utility)
    private var timer: DispatchSourceTimer?

    internal init() { }

    /// Starts polling the agent heartbeat.
    ///
    /// Does nothing when the license key is blank, mirroring the `licensekey.isBlank()` guard in
    /// `AgentHeartbeatScheduler.init()` on Android.
    ///
    /// - Parameters:
    ///   - configuration: The heartbeat inputs.
    ///   - instanceName: The name of the SDK instance whose consent is toggled.
    public func start(
        configuration: HeartbeatConfiguration,
        instanceName: String = CoreRegistry.defaultInstanceName
    ) {
        guard !configuration.licenseKey.isEmpty else {
            AT.logger.debug("AgentHeartbeatScheduler.start() skipped: license key is blank")
            return
        }
        guard !isRunning else {
            return
        }
        isRunning = true

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: Self.pollingInterval)
        timer.setEventHandler {
            AgentHeartbeat.check(path: AgentHeartbeat.agentHeartbeatPath, configuration: configuration) { allowed in
                AT.logger.debug("Agent heartbeat allowed = \(allowed)")
                Atatus.setAgentEnabled(allowed, instanceName: instanceName)
            }
        }
        self.timer = timer
        timer.resume()
    }

    /// Stops polling the agent heartbeat.
    public func stop() {
        guard isRunning else {
            return
        }
        isRunning = false
        timer?.cancel()
        timer = nil
    }
}

extension Atatus {
    /// Enables or disables data collection for the given SDK instance.
    ///
    /// Collection is suspended through tracking consent rather than by stopping the SDK, so the
    /// instance stays alive and can be resumed by a later heartbeat. This mirrors
    /// `Atatus.setAgentEnabled` on Android.
    ///
    /// - Parameters:
    ///   - enabled: Whether the agent should collect and upload data.
    ///   - instanceName: The name of the SDK instance.
    public static func setAgentEnabled(
        _ enabled: Bool,
        instanceName: String = CoreRegistry.defaultInstanceName
    ) {
        guard Atatus.isInitialized(instanceName: instanceName) else {
            return
        }
        let core = CoreRegistry.instance(named: instanceName)
        if enabled {
            AT.logger.debug("Agent ENABLED")
            Atatus.set(trackingConsent: .granted, in: core)
        } else {
            AT.logger.debug("Agent DISABLED")
            Atatus.set(trackingConsent: .notGranted, in: core)
        }
    }
}
// ATCHG: End
