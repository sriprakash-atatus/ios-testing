/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

// ATCHG: New file, porting the heartbeat infrastructure from the Atatus Android agent
// (`atatus-sdk-android-core/src/main/kotlin/com/atatus/android/AgentInfo.kt`, which declares
// `AgentHeartbeat`, `AgentHeartbeatScheduler`, `LogsHeartbeat` and `LogsHeartbeatScheduler`).
//
// The heartbeat lets the Atatus backend switch the agent — and the Logs feature specifically —
// on and off remotely. Both endpoints answer with `{"allowAgent": <bool>}`.
//
// `AgentHeartbeatScheduler` lives in `AtatusCore` because it drives SDK initialisation and
// tracking consent; the pieces here are the ones the Logs feature also needs, and `AtatusLogs`
// only depends on `AtatusInternal`.

/// The inputs a heartbeat request needs.
public struct HeartbeatConfiguration {
    /// The intake endpoint of the configured site.
    public let endpoint: URL
    /// The license key allowing data uploads to Atatus.
    public let licenseKey: String
    /// The name of the instrumented application.
    public let appName: String
    /// The mobile platform, e.g. `"ios"`.
    public let source: String

    public init(endpoint: URL, licenseKey: String, appName: String, source: String) {
        self.endpoint = endpoint
        self.licenseKey = licenseKey
        self.appName = appName
        self.source = source
    }
}

/// Performs a single heartbeat request against a given path.
public enum AgentHeartbeat {
    /// The path of the agent heartbeat, matching `/v1/android/agent-heartbeat` on Android.
    public static let agentHeartbeatPath = "v1/ios/agent-heartbeat"
    /// The path of the logs heartbeat, matching `/v1/android/log/heart-beat` on Android.
    public static let logsHeartbeatPath = "v1/ios/log/heart-beat"

    /// Timeout applied to heartbeat requests, matching the 5s connect/read timeouts on Android.
    internal static let timeout: TimeInterval = 5

    /// Queries the heartbeat endpoint and reports whether the agent is allowed to send data.
    ///
    /// - Parameters:
    ///   - path: The heartbeat path, either ``agentHeartbeatPath`` or ``logsHeartbeatPath``.
    ///   - configuration: The heartbeat inputs.
    ///   - session: The session performing the request.
    ///   - completion: Called with `true` only when the backend answers `200` with `allowAgent: true`.
    public static func check(
        path: String,
        configuration: HeartbeatConfiguration,
        session: URLSession = .shared,
        completion: @escaping (Bool) -> Void
    ) {
        // Skip the heartbeat if the license key is not set, to avoid a 400 "API Key is missing".
        guard !configuration.licenseKey.isEmpty else {
            AT.logger.debug("Heartbeat skipped: license key is blank")
            completion(false)
            return
        }

        guard let url = heartbeatURL(path: path, configuration: configuration) else {
            AT.logger.debug("Heartbeat skipped: could not build heartbeat URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                AT.logger.debug("Heartbeat error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(false)
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let allowAgent = json["allowAgent"] as? Bool
            else {
                completion(false)
                return
            }

            completion(allowAgent)
        }
        .resume()
    }

    internal static func heartbeatURL(path: String, configuration: HeartbeatConfiguration) -> URL? {
        let url = configuration.endpoint.appendingPathComponent(path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "atatus_source", value: configuration.source),
            URLQueryItem(name: "license_key", value: configuration.licenseKey),
            URLQueryItem(name: "agent_name", value: AgentInfo.agentName),
            URLQueryItem(name: "agent_version", value: AgentInfo.agentVersion),
            URLQueryItem(name: "app_name", value: configuration.appName)
        ]
        return components?.url
    }
}

/// Polls the logs heartbeat and gates uploads of the Logs feature.
///
/// Mirrors `LogsHeartbeatScheduler` on Android: the Logs request builder consults
/// ``isLogsAllowed`` and skips the batch while logs are disabled.
public final class LogsHeartbeatScheduler {
    /// The shared scheduler consulted by the Logs feature.
    public static let shared = LogsHeartbeatScheduler()

    /// The polling interval, matching the 30 minutes used on Android.
    public static let pollingInterval: TimeInterval = 30 * 60

    /// Whether the backend currently allows logs to be uploaded.
    ///
    /// Defaults to `false`, matching `LogsHeartbeatScheduler.isLogsAllowed` on Android: log
    /// batches are held back until the first heartbeat answers `allowAgent: true`.
    @ReadWriteLock
    public private(set) static var isLogsAllowed = false

    /// Overrides ``isLogsAllowed``.
    ///
    /// Exposed so tests and cross-platform agents can drive the gate without a live heartbeat;
    /// on Android the field is only mutated by the scheduler itself.
    @_spi(Internal)
    public static func setLogsAllowed(_ allowed: Bool) {
        isLogsAllowed = allowed
    }

    @ReadWriteLock
    private var isRunning = false

    private let queue = DispatchQueue(label: "com.atatus.logs-heartbeat", qos: .utility)
    private var timer: DispatchSourceTimer?

    internal init() { }

    /// Starts polling the logs heartbeat.
    ///
    /// Does nothing when the license key is blank, mirroring the `licensekey.isBlank()` guard in
    /// `LogsHeartbeatScheduler.init()` on Android.
    public func start(configuration: HeartbeatConfiguration) {
        guard !configuration.licenseKey.isEmpty else {
            AT.logger.debug("LogsHeartbeatScheduler.start() skipped: license key is blank")
            return
        }
        guard !isRunning else {
            return
        }
        isRunning = true

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: Self.pollingInterval)
        timer.setEventHandler {
            AgentHeartbeat.check(path: AgentHeartbeat.logsHeartbeatPath, configuration: configuration) { allowed in
                AT.logger.debug("Logs heartbeat allowed = \(allowed)")
                LogsHeartbeatScheduler.setLogsAllowed(allowed)
            }
        }
        self.timer = timer
        timer.resume()
    }

    /// Stops polling the logs heartbeat.
    public func stop() {
        guard isRunning else {
            return
        }
        isRunning = false
        timer?.cancel()
        timer = nil
    }
}
// ATCHG: End
