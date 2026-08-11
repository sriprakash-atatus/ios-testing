/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddBenchmarks` -> `AtatusBenchmarks`,
// `ddInternal` -> `AtatusInternal`; rebranded the licence header.

import Foundation
import AtatusInternal
import AtatusBenchmarks
import OpenTelemetryApi
import OpenTelemetrySdk

internal final class Meter: AtatusInternal.BenchmarkMeter {
    let meter: MeterSdk

    init(provider: MeterProviderSdk) {
        self.meter = provider.get(name: "benchmarks")
    }

    func counter(metric: @autoclosure () -> String) -> AtatusInternal.BenchmarkCounter {
        DoubleCounterWrapper(counter: meter.counterBuilder(name: metric()).ofDoubles().build())
    }

    func gauge(metric: @autoclosure () -> String) -> AtatusInternal.BenchmarkGauge {
        DoubleGaugeWrapper(gauge: meter.gaugeBuilder(name: metric()).build())
    }

    func observe(metric: @autoclosure () -> String, callback: @escaping (any AtatusInternal.BenchmarkGauge) -> Void) {
        _ = meter.gaugeBuilder(name: metric()).buildWithCallback { callback(ObservableDoubleMeasurementWrapper(measurement: $0)) }
    }
}

private final class DoubleCounterWrapper: AtatusInternal.BenchmarkCounter {
    var counter: DoubleCounterSdk

    init(counter: DoubleCounterSdk) {
        self.counter = counter
    }

    func add(value: Double, attributes: @autoclosure () -> [String: String]) {
        counter.add(value: value, attributes: attributes().mapValues { AttributeValue.string($0) })
    }
}

private final class DoubleGaugeWrapper: AtatusInternal.BenchmarkGauge {
    let gauge: DoubleGaugeSdk

    init(gauge: DoubleGaugeSdk) {
        self.gauge = gauge
    }

    func record(value: Double, attributes: @autoclosure () -> [String: String]) {
        gauge.record(value: value, attributes: attributes().mapValues { AttributeValue.string($0) })
    }
}

private struct ObservableDoubleMeasurementWrapper: AtatusInternal.BenchmarkGauge {
    let measurement: ObservableMeasurementSdk

    func record(value: Double, attributes: @autoclosure () -> [String: String]) {
        measurement.record(value: value, attributes: attributes().mapValues { AttributeValue.string($0) })
    }
}
