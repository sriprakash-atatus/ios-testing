/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed `dd*` types to `Atatus*`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@testable import AtatusRUM

final class AppLaunchMetricControllerTests: XCTestCase {
    private let telemetry = TelemetryMock()

    func testTrackingAppLaunchMetric() throws {
        // Given
        let atatusContext: AtatusContext = .mockRandom()
        let vitalEvent: RUMVitalAppLaunchEvent = .mockWith(
            vital: .mockWith(
                appLaunchMetric: .ttid,
                isPrewarmed: atatusContext.launchInfo.launchReason == .prewarming
            )
        )
        let coldStartRule: ColdStartRule = .appUpdate
        let controller = AppLaunchMetricController(telemetry: telemetry)

        // When
        controller.track(coldStartRule: coldStartRule)
        controller.track(ttidEvent: vitalEvent, context: atatusContext)
        controller.sendMetric()

        // Then
        let metric = try XCTUnwrap(telemetry.messages.appLaunchMetric)
        XCTAssertEqual(metric.ttidDurationNs, vitalEvent.vital.duration.dd.toInt64Nanoseconds)
        XCTAssertEqual(metric.startupType, vitalEvent.vital.startupType?.rawValue)
        XCTAssertEqual(metric.coldStartRule, coldStartRule.rawValue)
        XCTAssertEqual(metric.isPrewarmed, vitalEvent.vital.isPrewarmed)
        XCTAssertEqual(metric.launchReason, atatusContext.launchInfo.launchReason)
        XCTAssertEqual(metric.taskPolicyRole, atatusContext.launchInfo.raw.taskPolicyRole)
        XCTAssertEqual(metric.pois.count, 5)

        let metricTelemetry = try XCTUnwrap(telemetry.messages.lastMetric(named: AppLaunchMetric.Constants.name))
        XCTAssertEqual(metricTelemetry.sampleRate, 20.0)
    }

    func testTrackingLargeTTID() throws {
        // Given
        let atatusContext: AtatusContext = .mockRandom()
        let controller = AppLaunchMetricController(telemetry: telemetry)
        let duration: TimeInterval = 1_000

        // When
        controller.send(metric: .largeTTID(context: atatusContext, duration: duration))

        // Then
        let metric = try XCTUnwrap(telemetry.messages.appLaunchMetric)
        XCTAssertEqual(metric.ttidDurationNs, duration.dd.toInt64Nanoseconds)
        XCTAssertEqual(metric.launchReason, atatusContext.launchInfo.launchReason)
        XCTAssertEqual(metric.taskPolicyRole, atatusContext.launchInfo.raw.taskPolicyRole)
        XCTAssertEqual(metric.isPrewarmed, atatusContext.launchInfo.launchReason == .prewarming)
        XCTAssertEqual(metric.pois.count, 5)
        XCTAssertFalse(metric.errorMessage?.isEmpty ?? true)

        let metricTelemetry = try XCTUnwrap(telemetry.messages.lastMetric(named: AppLaunchMetric.Constants.name))
        XCTAssertEqual(metricTelemetry.sampleRate, 20.0)
    }

    func testTrackingLaunchNotSupported() throws {
        // Given
        let atatusContext: AtatusContext = .mockRandom()
        let controller = AppLaunchMetricController(telemetry: telemetry)
        let duration: TimeInterval = 1_000

        // When
        controller.send(metric: .launchNotSupported(context: atatusContext, duration: duration))

        // Then
        let metric = try XCTUnwrap(telemetry.messages.appLaunchMetric)
        XCTAssertEqual(metric.ttidDurationNs, duration.dd.toInt64Nanoseconds)
        XCTAssertEqual(metric.launchReason, atatusContext.launchInfo.launchReason)
        XCTAssertEqual(metric.taskPolicyRole, atatusContext.launchInfo.raw.taskPolicyRole)
        XCTAssertEqual(metric.isPrewarmed, atatusContext.launchInfo.launchReason == .prewarming)
        XCTAssertEqual(metric.pois.count, 5)
        XCTAssertFalse(metric.errorMessage?.isEmpty ?? true)

        let metricTelemetry = try XCTUnwrap(telemetry.messages.lastMetric(named: AppLaunchMetric.Constants.name))
        XCTAssertEqual(metricTelemetry.sampleRate, 20.0)
    }

    func testTrackingAppLaunchMetric_withTTFDRecordedFirst() throws {
        // Given
        let atatusContext: AtatusContext = .mockRandom()
        let vitalEvent: RUMVitalAppLaunchEvent = .mockAny()
        let controller = AppLaunchMetricController(telemetry: telemetry)
        let ttfdDuration: Int64 = 1_000

        // When
        controller.track(ttidEvent: vitalEvent, context: atatusContext)
        controller.trackTTFD(duration: ttfdDuration)
        controller.sendMetric()

        // Then
        let metric = try XCTUnwrap(telemetry.messages.appLaunchMetric)
        XCTAssertEqual(metric.ttidDurationNs, vitalEvent.vital.duration.dd.toInt64Nanoseconds)
        XCTAssertEqual(metric.startupType, vitalEvent.vital.startupType?.rawValue)
        XCTAssertEqual(metric.launchReason, atatusContext.launchInfo.launchReason)
        XCTAssertEqual(metric.taskPolicyRole, atatusContext.launchInfo.raw.taskPolicyRole)
        XCTAssertEqual(metric.pois.count, 5)
        XCTAssertEqual(metric.ttfdDurationNs, ttfdDuration)

        let metricTelemetry = try XCTUnwrap(telemetry.messages.lastMetric(named: AppLaunchMetric.Constants.name))
        XCTAssertEqual(metricTelemetry.sampleRate, 20.0)
    }

    func testTrackingMoreThanOneTTID() throws {
        // Given
        let atatusContext: AtatusContext = .mockRandom()
        let vitalEvent: RUMVitalAppLaunchEvent = .mockAny()
        let controller = AppLaunchMetricController(telemetry: telemetry)

        // When
        controller.track(ttidEvent: vitalEvent, context: atatusContext)
        controller.incrementTTIDCounter()
        controller.incrementTTIDCounter()
        controller.sendMetric()

        // Then
        let metric = try XCTUnwrap(telemetry.messages.appLaunchMetric)
        XCTAssertEqual(metric.ttidDurationNs, vitalEvent.vital.duration.dd.toInt64Nanoseconds)
        XCTAssertEqual(metric.startupType, vitalEvent.vital.startupType?.rawValue)
        XCTAssertEqual(metric.launchReason, atatusContext.launchInfo.launchReason)
        XCTAssertEqual(metric.taskPolicyRole, atatusContext.launchInfo.raw.taskPolicyRole)
        XCTAssertEqual(metric.pois.count, 5)
        XCTAssertEqual(metric.extraTTIDsCount, 2)

        let metricTelemetry = try XCTUnwrap(telemetry.messages.lastMetric(named: AppLaunchMetric.Constants.name))
        XCTAssertEqual(metricTelemetry.sampleRate, 20.0)
    }

    func testTrackingMultipleAppLaunchMetrics() throws {
        // Given
        let iterations = 10
        let atatusContext: AtatusContext = .mockRandom()
        let vitalEvent: RUMVitalAppLaunchEvent = .mockAny()
        let controller = AppLaunchMetricController(telemetry: telemetry)
        let appLaunchMetric = try XCTUnwrap(AppLaunchMetric(vitalEvent: vitalEvent, context: atatusContext))

        // When
        (0..<iterations).forEach { _ in
            controller.send(metric: appLaunchMetric)
        }

        // Then
        XCTAssertEqual(telemetry.messages.count, iterations)
        try (0..<iterations).forEach {
            let metric = try XCTUnwrap(telemetry.messages[$0]
                .asMetric?.attributes[AppLaunchMetric.Constants.appLaunchKey] as? AppLaunchMetric.Attributes)

            XCTAssertEqual(metric.ttidDurationNs, vitalEvent.vital.duration.dd.toInt64Nanoseconds)
            XCTAssertEqual(metric.startupType, vitalEvent.vital.startupType?.rawValue)
            XCTAssertEqual(metric.launchReason, atatusContext.launchInfo.launchReason)
            XCTAssertEqual(metric.taskPolicyRole, atatusContext.launchInfo.raw.taskPolicyRole)
            XCTAssertEqual(metric.pois.count, 5)
        }
    }
}

// MARK: - Helpers

private extension Array where Element == TelemetryMessage {
    var appLaunchMetric: AppLaunchMetric.Attributes? {
        lastMetric(named: AppLaunchMetric.Constants.name)?
            .attributes[AppLaunchMetric.Constants.appLaunchKey] as? AppLaunchMetric.Attributes
    }
}
