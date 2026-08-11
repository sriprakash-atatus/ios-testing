/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

import Foundation
import AtatusInternal

#if !os(watchOS)

extension Profiling {
    /// Configuration options for the profiling feature.
    public struct Configuration {
        /// Overrides the custom server endpoint where Profiles are sent.
        /// If `nil`, the default Atatus endpoint will be used.
        public var customEndpoint: URL?

        /// The sampling rate for App Launch Profiling.
        ///
        /// It must be a number between 0.0 and 100.0, where 0 means no profiles will be collected.
        ///
        /// Default: `5.0`.
        public var applicationLaunchSampleRate: SampleRate

        /// The sampling rate for continuous Profiling.
        ///
        /// It must be a number between 0.0 and 100.0, where 0 means no profiles will be collected.
        ///
        /// Default: `5.0`.
        public var continuousSampleRate: SampleRate

        // MARK: - Internal

        internal var debugSDK: Bool = ProcessInfo.processInfo.arguments.contains(LaunchArguments.Debug)
        internal var minProfileDuration: TimeInterval = AtatusProfiler.Constants.minProfileDuration

        /// Creates the Profiling configuration.
        /// - Parameters:
        ///   - customEndpoint: Optional custom server endpoint for profile uploads.
        ///   - applicationLaunchSampleRate: The sampling rate for the application launch profiling.
        public init(
            customEndpoint: URL? = nil,
            applicationLaunchSampleRate: SampleRate = 5,
            continuousSampleRate: SampleRate = 5
        ) {
            self.customEndpoint = customEndpoint
            self.applicationLaunchSampleRate = applicationLaunchSampleRate
            self.continuousSampleRate = continuousSampleRate
        }
    }
}

#endif
