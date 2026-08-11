/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddMachProfiler` -> `AtatusMachProfiler`; renamed `dd*` types to `Atatus*`; renamed the `DD`
// symbol prefix to `AT`; rebranded the licence header.

import Foundation
import AtatusInternal

#if !os(watchOS)

// swiftlint:disable duplicate_imports
#if swift(>=6.0)
internal import AtatusMachProfiler
#else
@_implementationOnly import AtatusMachProfiler
#endif
// swiftlint:enable duplicate_imports

internal final class ProfilerFeature: AtatusRemoteFeature {
    enum Constants {
        static let maxFileSize = 10.MB.asUInt32()
        static let maxObjectSize = 10.MB.asUInt32()
        static let maxObjectsInFile = 1
    }
    static let name = "profiler"

    let profilingSamplerProvider: ProfilingSamplerProvider
    let telemetryController: ProfilingTelemetryController
    let requestBuilder: FeatureRequestBuilder
    let messageReceiver: FeatureMessageReceiver

    /// Setting max-file-age to minimum will force creating a batch per profile.
    /// It is necessary as the profiling intake only accepts one profile per request.
    let performanceOverride: PerformancePresetOverride? = PerformancePresetOverride(
        // Add 5 MB to accommodate base64 expansion when encoding the pprof attachment.
        maxFileSize: Constants.maxFileSize + 5.MB.asUInt32(),
        maxObjectSize: Constants.maxObjectSize + 5.MB.asUInt32(),
        maxObjectsInFile: Constants.maxObjectsInFile
    )

    init(
        core: AtatusCoreProtocol,
        configuration: Profiling.Configuration,
        requestBuilder: FeatureRequestBuilder,
        telemetryController: ProfilingTelemetryController,
        quotaChecker: ProfilingQuotaChecking = ProfilingQuotaChecker(),
        userDefaults: UserDefaults = UserDefaults(suiteName: AT_PROFILING_USER_DEFAULTS_SUITE_NAME) ?? .standard //swiftlint:disable:this required_reason_api_name
    ) {
        self.requestBuilder = requestBuilder
        self.telemetryController = telemetryController

        let continuousSampleRate = configuration.debugSDK ? .maxSampleRate : configuration.continuousSampleRate
        self.profilingSamplerProvider = ProfilingSamplerProvider(continuousSampleRate: continuousSampleRate)

        var messageReceivers: [FeatureMessageReceiver] = [
            ProfilingContextMessageReceiver(profilingSamplerProvider: profilingSamplerProvider)
        ]

        messageReceivers.append(
            AppLaunchProfiler(
                core: core,
                profilingSamplerProvider: profilingSamplerProvider,
                quotaChecker: quotaChecker,
                telemetryController: telemetryController
            )
        )

        messageReceivers.append(quotaChecker)

        if let atatusProfiler = AtatusProfiler(
            core: core,
            profilingSamplerProvider: profilingSamplerProvider,
            quotaChecker: quotaChecker,
            telemetryController: telemetryController,
            minProfileDuration: configuration.minProfileDuration
        ) {
            messageReceivers.append(atatusProfiler)
        }

        self.messageReceiver = CombinedFeatureMessageReceiver(messageReceivers)

        setProfilingEnabled(in: userDefaults)
        let sampleRate = configuration.debugSDK ? .maxSampleRate : configuration.applicationLaunchSampleRate
        setAppLaunch(sampleRate: sampleRate, in: userDefaults)
    }

    private func setProfilingEnabled(in userDefaults: UserDefaults) { //swiftlint:disable:this required_reason_api_name
        userDefaults.setValue(true, forKey: AT_PROFILING_IS_ENABLED_KEY)
    }

    private func setAppLaunch(sampleRate: SampleRate, in userDefaults: UserDefaults) { //swiftlint:disable:this required_reason_api_name
        let previousSampleRate = userDefaults.value(forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY) as? SampleRate

        // Profiling will use the lowest sample rate
        // if there is more than one SDK instance initialized.
        if previousSampleRate == nil || previousSampleRate ?? .maxSampleRate > sampleRate {
            userDefaults.setValue(sampleRate, forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY)
        }
    }
}

#endif
