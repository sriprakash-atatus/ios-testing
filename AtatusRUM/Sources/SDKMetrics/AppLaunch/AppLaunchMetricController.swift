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

/// Controller responsible for managing "RUM App Launch" metrics.
internal final class AppLaunchMetricController {
    /// The default sample rate for "RUM App Launch" metric (20%),
    /// applied in addition to the telemetry sample rate (20% by default).
    static let defaultSampleRate: SampleRate = 20
    /// Telemetry endpoint for sending metrics.
    let telemetry: Telemetry
    /// The sample rate for "RUM App Launch" metric.
    let sampleRate: SampleRate

    /// Metric that wraps all the app launch details.
    private var appLaunchMetric: AppLaunchMetric?

    /// Rule used to determine the "cold_start" type.
    private var coldStartRule: ColdStartRule?

    init(
        sampleRate: SampleRate = AppLaunchMetricController.defaultSampleRate,
        telemetry: Telemetry = NOPTelemetry()
    ) {
        self.sampleRate = sampleRate
        self.telemetry = telemetry
    }

    /// Sends the telemetry metric.
    func sendMetric() {
        guard let appLaunchMetric else {
            return
        }

        send(metric: appLaunchMetric)

        // The metric will be reported only once
        self.appLaunchMetric = nil
    }

    /// Sends the telemetry metric.
    func send(metric appLaunchMetric: AppLaunchMetric) {
        guard let metricAttributes = appLaunchMetric.asMetricAttributes() else {
            telemetry.debug("Failed to compute attributes for app launch metric.")
            return
        }

        telemetry.metric(name: appLaunchMetric.metricName, attributes: metricAttributes, sampleRate: sampleRate)
    }

    /// Tracks the TTID info with the Atatus context.
    func track(ttidEvent: RUMVitalAppLaunchEvent, context: AtatusContext) {
        appLaunchMetric = .init(vitalEvent: ttidEvent, context: context, coldStartRule: coldStartRule)
    }

    /// Tracks the rule used to determine a  "cold_start" type.
    func track(coldStartRule: ColdStartRule) {
        self.coldStartRule = coldStartRule
    }

    /// Increments the number of extra TTIDs collected.
    func incrementTTIDCounter() {
        appLaunchMetric?.incrementTTIDCounter()
    }

    /// Tracks the duration of the TTFD vital.
    func trackTTFD(duration: Int64) {
        appLaunchMetric?.track(ttfd: duration)
    }
}
