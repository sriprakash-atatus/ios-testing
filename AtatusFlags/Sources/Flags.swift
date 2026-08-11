/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddFlags` ->
// `AtatusFlags`, `ddInternal` -> `AtatusInternal`; renamed `dd*` types to `Atatus*`; renamed
// `clientToken` to `licenseKey`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

import Foundation
import AtatusInternal

/// Atatus Feature Flags SDK.
///
/// The Flags SDK enables feature flag evaluation and management in your iOS application,
/// integrating with Atatus's feature flag service for dynamic configuration and experimentation.
///
/// To use feature flags in your application:
///
/// 1. Enable the Flags feature after initializing the Atatus SDK
/// 2. Create a `FlagsClient` to evaluate flags
/// 3. Set the evaluation context with user/session information
/// 4. Evaluate flags throughout your application
public enum Flags {
    /// Configuration options for the Atatus Flags feature.
    ///
    /// Use this type to customize the behavior of feature flag evaluation, including custom endpoints,
    /// exposure tracking, and error handling modes.
    public struct Configuration {
        /// Controls error handling behavior for `FlagsClient` API misuse.
        ///
        /// This setting determines how the SDK responds to incorrect usage, such as:
        /// - Creating a `FlagsClient` that already exists
        /// - Retrieving a `FlagsClient` that was never created
        /// - Creating a `FlagsClient` before calling `Flags.enable()`
        ///
        /// Error handling is selected based on the build configuration and this setting:
        /// - Release builds use safe defaults with SDK level-based logging
        /// - Debug builds with `gracefulModeEnabled = true` log warnings to console instead of crashing
        /// - Debug builds with `gracefulModeEnabled = false` crashes with fatal errors for fail-fast development
        ///
        /// Recommended usage:
        /// - Set to `false` in development, test, and QA builds for immediate error detection
        /// - Set to `true` (default) in dogfooding and staging environments for visible warnings without crashes
        /// - Production builds always handle errors gracefully regardless of this setting
        ///
        /// Default: `true`.
        public var gracefulModeEnabled: Bool

        /// Custom server URL for retrieving flag assignments.
        ///
        /// If not set, the SDK uses the default Atatus Flags endpoint for the configured site.
        ///
        /// Default: `nil`.
        public var customFlagsEndpoint: URL?

        /// Additional HTTP headers to attach to requests made to `customFlagsEndpoint`.
        ///
        /// Useful for authentication or routing when using your own Flags service. Ignored when using the default Atatus endpoint.
        ///
        /// Default: `nil`.
        public var customFlagsHeaders: [String: String]?

        /// Custom server url for sending Flags exposure data.
        ///
        /// Default: `nil`.
        public var customExposureEndpoint: URL?

        /// Enables exposure logging via the dedicated exposures intake endpoint.
        ///
        /// When enabled, flag evaluation events are sent to the exposures endpoint for analytics and monitoring.
        ///
        /// Default: `true`.
        public var trackExposures: Bool

        /// Custom server url for sending Flags evaluation data.
        ///
        /// Default: `nil`.
        public var customEvaluationEndpoint: URL?

        /// Enables evaluation logging via the dedicated evaluations intake endpoint.
        ///
        /// When enabled, all flag evaluations are aggregated and sent to the evaluations endpoint for operational monitoring.
        ///
        /// Default: `true`.
        public var trackEvaluations: Bool

        /// The interval at which aggregated evaluation data is flushed to the server.
        ///
        /// Values are clamped to a minimum of 1 second and maximum of 60 seconds.
        ///
        /// Default: `10.0` seconds.
        public var evaluationFlushInterval: TimeInterval

        /// Enables the RUM integration.
        ///
        /// When enabled, flag evaluation events are sent to RUM for correlation with user sessions.
        ///
        /// Default: `true`.
        public var rumIntegrationEnabled: Bool

        /// Creates a configuration for the Atatus Flags feature.
        ///
        /// - Parameters:
        ///   - gracefulModeEnabled: Controls error handling behavior for API misuse. Default: `true`.
        ///   - customFlagsEndpoint: Custom server URL for retrieving flag assignments. Default: `nil`.
        ///   - customFlagsHeaders: Additional HTTP headers for requests to `customFlagsEndpoint`. Default: `nil`.
        ///   - customExposureEndpoint: Custom server URL for sending exposure data. Default: `nil`.
        ///   - trackExposures: Enables exposure logging to the exposures intake endpoint. Default: `true`.
        ///   - customEvaluationEndpoint: Custom server URL for sending evaluation data. Default: `nil`.
        ///   - trackEvaluations: Enables evaluation logging to the evaluations intake endpoint. Default: `true`.
        ///   - evaluationFlushInterval: The interval for flushing aggregated evaluation data. Default: `10.0` seconds.
        ///   - rumIntegrationEnabled: Enables the RUM integration for flag evaluations. Default: `true`.
        public init(
            gracefulModeEnabled: Bool = true,
            customFlagsEndpoint: URL? = nil,
            customFlagsHeaders: [String: String]? = nil,
            customExposureEndpoint: URL? = nil,
            trackExposures: Bool = true,
            customEvaluationEndpoint: URL? = nil,
            trackEvaluations: Bool = true,
            evaluationFlushInterval: TimeInterval = 10.0,
            rumIntegrationEnabled: Bool = true
        ) {
            self.gracefulModeEnabled = gracefulModeEnabled
            self.customFlagsEndpoint = customFlagsEndpoint
            self.customFlagsHeaders = customFlagsHeaders
            self.customExposureEndpoint = customExposureEndpoint
            self.trackExposures = trackExposures
            self.customEvaluationEndpoint = customEvaluationEndpoint
            self.trackEvaluations = trackEvaluations
            self.evaluationFlushInterval = evaluationFlushInterval
            self.rumIntegrationEnabled = rumIntegrationEnabled
        }
    }

    /// Enables the Atatus Flags feature in your application.
    ///
    /// Call this method after initializing the Atatus SDK to enable feature flag evaluation.
    /// This method must be called before creating any `FlagsClient` instances.
    ///
    /// ```swift
    /// import AtatusCore
    /// import AtatusFlags
    ///
    /// // Initialize Atatus SDK
    /// Atatus.initialize(
    ///     with: Atatus.Configuration(
    ///         licenseKey: "<client_token>",
    ///         env: "<environment>"
    ///     ),
    ///     trackingConsent: .granted
    /// )
    ///
    /// // Enable Flags feature
    /// Flags.enable()
    /// ```
    ///
    /// - Parameters:
    ///   - configuration: Configuration options for the Flags feature. Defaults to standard configuration.
    ///   - core: The Atatus SDK core instance. Defaults to the global shared instance.
    public static func enable(
        with configuration: Flags.Configuration = .init(),
        in core: AtatusCoreProtocol = CoreRegistry.default
    ) {
        do {
            // To ensure the correct registration order between Core and Features,
            // the entire initialization flow is synchronized on the main thread.
            try runOnMainThreadSync {
                try enableOrThrow(with: configuration, in: core)
            }
        } catch let error {
            consolePrint("\(error)", .error)
        }
    }

    internal static func enableOrThrow(
        with configuration: Flags.Configuration,
        in core: AtatusCoreProtocol
    ) throws {
        guard !(core is NOPAtatusCore) else {
            throw ProgrammerError(
                description: "Atatus SDK must be initialized before calling `Flags.enable(with:)`."
            )
        }

        if configuration.trackEvaluations {
            let evaluationFeature = FlagsEvaluationFeature(
                customIntakeURL: configuration.customEvaluationEndpoint,
                telemetry: core.telemetry
            )
            try core.register(feature: evaluationFeature)
        }

        let featureScope = core.scope(for: FlagsFeature.self) // safe to obtain scope before feature registration; scope is lazily evaluated
        let feature = FlagsFeature(
            configuration: configuration,
            featureScope: featureScope,
            core: core
        )
        try core.register(feature: feature)
    }
}
