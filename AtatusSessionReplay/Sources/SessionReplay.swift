/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed `dd*` members to `at*`; rebranded the `dd` name to `Atatus`
// in comments and docs; rebranded the licence header.

#if os(iOS)
import Foundation
import AtatusInternal

/// An entry point to Atatus Session Replay feature.
public enum SessionReplay {
    /// Enables Atatus Session Replay feature.
    ///
    /// Recording will start automatically after enabling Session Replay.
    ///
    /// Note: Session Replay requires the RUM feature to be enabled.
    ///
    /// - Parameters:
    ///   - configuration: Configuration of the feature.
    ///   - core: The instance of Atatus SDK to enable Session Replay in (global instance by default).
    public static func enable(
        with configuration: SessionReplay.Configuration,
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

    /// Starts the recording manually.
    /// - Parameters:
    ///   - core: The instance of Atatus SDK to start Session Replay in (global instance by default).
    public static func startRecording(
        in core: AtatusCoreProtocol = CoreRegistry.default
    ) {
        do {
            try startRecording(core: core)
        } catch let error {
            consolePrint("\(error)", .error)
        }
    }

    /// Stops the recording manually.
    /// - Parameters:
    ///   - core: The instance of Atatus SDK to start Session Replay in (global instance by default).
    public static func stopRecording(
        in core: AtatusCoreProtocol = CoreRegistry.default
    ) {
        do {
            try stopRecording(core: core)
        } catch let error {
            consolePrint("\(error)", .error)
        }
    }

    // MARK: Internal

    internal static let maxObjectSize = 10.MB.asUInt32()

    internal static func enableOrThrow(
        with configuration: SessionReplay.Configuration,
        in core: AtatusCoreProtocol
    ) throws {
        guard !(core is NOPAtatusCore) else {
            throw ProgrammerError(
                description: "Atatus SDK must be initialized before calling `SessionReplay.enable(with:)`."
            )
        }

        guard !CoreRegistry.isFeatureEnabled(feature: SessionReplayFeature.self) else {
            core.telemetry.debug("Session Replay has already been enabled")
            throw ProgrammerError(
                description: "Session Replay is already enabled and does not support multiple instances. The existing instance will continue to be used."
            )
        }

        guard configuration.replaySampleRate > 0 else {
            return
        }
        let resources = ResourcesFeature(core: core, configuration: configuration)
        try core.register(feature: resources)

        let sessionReplay = try SessionReplayFeature(core: core, configuration: configuration)
        try core.register(feature: sessionReplay)
        core.set(
            context: SessionReplayCoreContext.Configuration(
                sampleRate: configuration.replaySampleRate,
                startRecordingManually: !configuration.startRecordingImmediately,
                experimentalFeatures: configuration.featureFlags.stringValues
            )
        )

        core.telemetry.configuration(
            defaultPrivacyLevel: nil,
            textAndInputPrivacyLevel: configuration.textAndInputPrivacyLevel.rawValue,
            imagePrivacyLevel: configuration.imagePrivacyLevel.rawValue,
            touchPrivacyLevel: configuration.touchPrivacyLevel.rawValue,
            sessionReplaySampleRate: Int64.atWithNoOverflow(configuration.replaySampleRate),
            startRecordingImmediately: configuration.startRecordingImmediately
        )
    }

    internal static func startRecording(core: AtatusCoreProtocol) throws {
        guard let sr = core.get(feature: SessionReplayFeature.self) else {
            throw ProgrammerError(
                description: "Session Replay must be initialized before calling `SessionReplay.startRecording()`."
            )
        }

        sr.startRecording()
    }

    internal static func stopRecording(core: AtatusCoreProtocol) throws {
        let sr = core.get(feature: SessionReplayFeature.self)
        sr?.stopRecording()
    }
}
#endif
