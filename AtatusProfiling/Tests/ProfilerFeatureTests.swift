/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddMachProfiler` -> `AtatusMachProfiler`, `ddProfiling` -> `AtatusProfiling`; renamed
// `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

#if !os(watchOS)

import XCTest
import AtatusInternal
import AtatusMachProfiler
import TestUtilities
@testable import AtatusProfiling

final class ProfilerFeatureTests: XCTestCase {
    private let core: AtatusCoreProtocol = PassthroughCoreMock()
    private let requestBuilder: FeatureRequestBuilder = FeatureRequestBuilderMock()
    private let telemetryController = ProfilingTelemetryController()

    private var userDefaults: UserDefaults! //swiftlint:disable:this implicitly_unwrapped_optional
    private let suiteName = "ProfilerFeatureTests-\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        AtatusProfiler.resetActiveInstance()
        dd_profiler_stop()
        dd_profiler_destroy()
        userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        AtatusProfiler.resetActiveInstance()
        dd_profiler_stop()
        dd_profiler_destroy()
        super.tearDown()
    }

    func testInit_setsIsEnabledFlagToTrue() {
        // Given
        XCTAssertNil(userDefaults.value(forKey: AT_PROFILING_IS_ENABLED_KEY))

        // When
        _ = ProfilerFeature(
            core: core,
            configuration: .init(),
            requestBuilder: requestBuilder,
            telemetryController: telemetryController,
            userDefaults: userDefaults
        )

        // Then
        XCTAssertEqual(userDefaults.value(forKey: AT_PROFILING_IS_ENABLED_KEY) as? Bool, true)
    }

    func testInit_setsSampleRateValue() {
        // Given
        userDefaults.removeObject(forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY)
        let newSampleRate: SampleRate = 23

        // When
        _ = ProfilerFeature(
            core: core,
            configuration: .init(applicationLaunchSampleRate: newSampleRate),
            requestBuilder: requestBuilder,
            telemetryController: telemetryController,
            userDefaults: userDefaults
        )

        // Then
        XCTAssertEqual(userDefaults.value(forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY) as? SampleRate, newSampleRate)
    }

    func testInit_overridesPreviousSampleRate_whenNewSampleRateIsLower() {
        // Given
        let previousSampleRate: SampleRate = 80
        let lowerSampleRate: SampleRate = 20

        userDefaults.setValue(previousSampleRate, forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY)
        XCTAssertEqual(userDefaults.value(forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY) as? SampleRate, previousSampleRate)

        // When
        _ = ProfilerFeature(
            core: core,
            configuration: .init(applicationLaunchSampleRate: lowerSampleRate),
            requestBuilder: requestBuilder,
            telemetryController: telemetryController,
            userDefaults: userDefaults
        )

        // Then
        XCTAssertEqual(userDefaults.value(forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY) as? SampleRate, lowerSampleRate)
    }

    func testInit_keepsPreviousSampleRate_whenNewSampleRateIsHigher() {
        // Given
        let previousSampleRate: SampleRate = 20
        let higherSampleRate: SampleRate = 80

        userDefaults.setValue(previousSampleRate, forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY)
        XCTAssertEqual(userDefaults.value(forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY) as? SampleRate, previousSampleRate)

        // When
        _ = ProfilerFeature(
            core: core,
            configuration: .init(applicationLaunchSampleRate: higherSampleRate),
            requestBuilder: requestBuilder,
            telemetryController: telemetryController,
            userDefaults: userDefaults
        )

        // Then
        XCTAssertEqual(userDefaults.value(forKey: AT_PROFILING_APP_LAUNCH_SAMPLE_RATE_KEY) as? SampleRate, previousSampleRate)
    }

    func testMessageReceiver_checksQuota_whenCustomEndpointIsConfigured() {
        // Given
        let quotaChecker = ProfilingQuotaCheckerMock()
        let feature = ProfilerFeature(
            core: core,
            configuration: .init(customEndpoint: .mockRandom()),
            requestBuilder: requestBuilder,
            telemetryController: telemetryController,
            quotaChecker: quotaChecker,
            userDefaults: userDefaults
        )
        let context: AtatusContext = .mockWith(
            trackingConsent: .granted,
            additionalContext: [RUMCoreContext.mockWith(sessionSampleRate: .maxSampleRate)]
        )

        // When
        _ = feature.messageReceiver.receive(message: .context(context), from: core)

        // Then
        XCTAssertEqual(quotaChecker.receivedContexts.count, 1)
    }

    func testMessageReceiver_checksQuotaForAppLaunchProfiler_whenAtatusProfilerIsNotCreated() {
        // Given
        let firstFeature = ProfilerFeature(
            core: PassthroughCoreMock(),
            configuration: .init(),
            requestBuilder: requestBuilder,
            telemetryController: telemetryController,
            userDefaults: userDefaults
        )
        let quotaChecker = ProfilingQuotaCheckerMock()
        let secondCore = PassthroughCoreMock()
        let secondFeature = ProfilerFeature(
            core: secondCore,
            configuration: .init(),
            requestBuilder: requestBuilder,
            telemetryController: telemetryController,
            quotaChecker: quotaChecker,
            userDefaults: userDefaults
        )
        let context: AtatusContext = .mockWith(
            trackingConsent: .granted,
            additionalContext: [RUMCoreContext.mockWith(sessionSampleRate: .maxSampleRate)]
        )

        // When
        _ = secondFeature.messageReceiver.receive(message: .context(context), from: secondCore)

        // Then
        XCTAssertEqual(quotaChecker.receivedContexts.count, 1)
        withExtendedLifetime(firstFeature) {}
        withExtendedLifetime(secondFeature) {}
    }

    func testProfilingSamplerProvider_isDeterministicForSameSessionID() {
        // Given
        let continuousSampleRate: SampleRate = 80
        let sessionUUID = "abcdef01-2345-6789-abcd-ef0123456789"
        let sessionSampler = DeterministicSampler(uuid: .mockWith(sessionUUID), samplingRate: 100)

        let firstProvider = ProfilingSamplerProvider(continuousSampleRate: continuousSampleRate)
        let secondProvider = ProfilingSamplerProvider(continuousSampleRate: continuousSampleRate)

        // When
        firstProvider.updateWith(deterministicSampler: sessionSampler)
        secondProvider.updateWith(deterministicSampler: sessionSampler)
        let firstDecision = firstProvider.continuousProfilingSampled
        let secondDecision = secondProvider.continuousProfilingSampled

        // Then
        XCTAssertEqual(firstDecision, firstProvider.continuousProfilingSampled)
        XCTAssertEqual(firstDecision, secondDecision)
    }

    func testProfilingSamplerProvider_hasNoContinuousProfilingDecision_withoutDeterministicSampler() {
        XCTAssertNil(ProfilingSamplerProvider(continuousSampleRate: 100).continuousProfilingSampled)
    }

    func testProfilingSamplerProvider_appliesChildRateCorrection() {
        // Given
        // seed 0xd860b2b9437a (~68.7% hash): NOT sampled at composed 40%, but sampled at profiling-only 80%.
        let sessionUUID = "a1b2c3d4-e5f6-7890-abcd-d860b2b9437a"
        let sessionSampleRate: SampleRate = 50
        let continuousSampleRate: SampleRate = 80
        let sessionSampler = DeterministicSampler(uuid: .mockWith(sessionUUID), samplingRate: sessionSampleRate)
        let expectedSampled = sessionSampler.combined(with: continuousSampleRate).isSampled
        let oldBehavior = DeterministicSampler(uuid: .mockWith(sessionUUID), samplingRate: continuousSampleRate).isSampled

        let provider = ProfilingSamplerProvider(continuousSampleRate: continuousSampleRate)

        // When
        provider.updateWith(deterministicSampler: sessionSampler)

        // Then
        XCTAssertNotEqual(expectedSampled, oldBehavior, "Chosen vector must differ between composed and profiling-only rate")
        XCTAssertEqual(provider.continuousProfilingSampled, expectedSampled)
    }

    func testMessageReceiver_updatesContinuousProfileSamplingWhenRUMContextChanges() {
        // Given
        let core = PassthroughCoreMock()
        let feature = ProfilerFeature(
            core: core,
            configuration: .init(continuousSampleRate: 100),
            requestBuilder: requestBuilder,
            telemetryController: telemetryController,
            userDefaults: userDefaults
        )

        let unsampledContext: AtatusContext = .mockWith(
            additionalContext: [RUMCoreContext.mockWith(sessionSampleRate: 0)]
        )
        let sampledContext: AtatusContext = .mockWith(
            additionalContext: [RUMCoreContext.mockWith(sessionSampleRate: 100)]
        )

        // When
        _ = feature.messageReceiver.receive(message: .context(unsampledContext), from: core)

        // Then
        XCTAssertEqual(feature.profilingSamplerProvider.continuousProfilingSampled, false)

        // When
        _ = feature.messageReceiver.receive(message: .context(sampledContext), from: core)

        // Then
        XCTAssertEqual(feature.profilingSamplerProvider.continuousProfilingSampled, true)
    }

    func testMessageReceiver_keepsPreviousContinuousProfileSampling_whenContextHasNoRUM() {
        // Given
        let core = PassthroughCoreMock()
        let feature = ProfilerFeature(
            core: core,
            configuration: .init(continuousSampleRate: 100),
            requestBuilder: requestBuilder,
            telemetryController: telemetryController,
            userDefaults: userDefaults
        )

        let unsampledContext: AtatusContext = .mockWith(
            additionalContext: [RUMCoreContext.mockWith(sessionSampleRate: 0)]
        )
        let contextWithoutRUM: AtatusContext = .mockWith(additionalContext: [])

        // When
        _ = feature.messageReceiver.receive(message: .context(unsampledContext), from: core)

        // Then
        XCTAssertEqual(feature.profilingSamplerProvider.continuousProfilingSampled, false)

        // When
        _ = feature.messageReceiver.receive(message: .context(contextWithoutRUM), from: core)

        // Then
        XCTAssertEqual(feature.profilingSamplerProvider.continuousProfilingSampled, false)
    }
}

#endif // !os(watchOS)
