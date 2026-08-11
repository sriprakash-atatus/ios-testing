/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; renamed the `DD-*` intake headers to their Atatus equivalents; repointed the intake host at the
// Atatus site; rebranded the `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import OpenTelemetrySdk

enum MetricExporterError: Error {
    case unsupportedMetric(type: MetricDataType, dataType: Any.Type)
}

/// Replacement of otel `AtatusExporter` for metrics.
///
/// This version does not store data to disk, it uploads to the intake directly.
/// Additionally, it does not crash.
final class MetricExporter: OpenTelemetrySdk.MetricExporter {
    struct Configuration {
        let apiKey: String
        let version: String
    }

    /// The type of metric. The available types are 0 (unspecified), 1 (count), 2 (rate), and 3 (gauge). Allowed enum values: 0,1,2,3
    enum MetricType: Int, Codable {
        case unspecified = 0
        case count = 1
        case rate = 2
        case gauge = 3
    }

    /// https://www.atatus.com/docs/
    internal struct Serie: Codable {
        struct Point: Codable {
            let timestamp: Int64
            let value: Double
        }

        struct Resource: Codable {
            let name: String
            let type: String
        }

        let type: MetricType
        let interval: Int64?
        let metric: String
        let unit: String?
        let points: [Point]
        let resources: [Resource]
        let tags: [String]
    }

    let session: URLSession
    let encoder = JSONEncoder()
    let configuration: Configuration

    // swiftlint:disable force_unwrapping
    let intake = URL(string: "https://www.atatus.com/")!
    let prefix = "{ \"series\": [".data(using: .utf8)!
    let separator = ",".data(using: .utf8)!
    let suffix = "]}".data(using: .utf8)!
    // swiftlint:enable force_unwrapping

    required init(configuration: Configuration) {
        let sessionConfiguration: URLSessionConfiguration = .ephemeral
        sessionConfiguration.urlCache = nil
        self.session = URLSession(configuration: sessionConfiguration)
        self.configuration = configuration
    }

    func export(metrics: [MetricData]) -> ExportResult {
        do {
            let series = try metrics.map(transform)
            try submit(series: series)
            return .success
        } catch {
            return .failure
        }
    }

    func flush() -> ExportResult {
        return .success
    }

    func shutdown() -> ExportResult {
        return .success
    }

    func getAggregationTemporality(for instrument: InstrumentType) -> AggregationTemporality {
        return .cumulative
    }

    /// Transforms otel `MetricData` to Atatus `serie`.
    ///
    /// - Parameter metric: The otel metric data
    /// - Returns: The timeserie.
    func transform(_ metric: MetricData) throws -> Serie {
        var tags = Set(metric.resource.attributes.map { "\($0):\($1)" })

        let points: [Serie.Point] = try metric.data.points.map { point in
            let timestamp = Int64(point.endEpochNanos / 1_000_000_000) // Convert nanos to seconds

            point.attributes.forEach { tags.insert("\($0):\($1)") }

            switch point {
            case let data as DoublePointData:
                return Serie.Point(timestamp: timestamp, value: data.value)
            case let data as LongPointData:
                return Serie.Point(timestamp: timestamp, value: Double(data.value))
            case let data as SummaryPointData:
                return Serie.Point(timestamp: timestamp, value: data.sum)
            default:
                throw MetricExporterError.unsupportedMetric(
                    type: metric.type,
                    dataType: type(of: point)
                )
            }
        }

        return Serie(
            type: MetricType(metric.type),
            interval: nil,
            metric: metric.name,
            unit: nil,
            points: points,
            resources: [],
            tags: Array(tags)
        )
    }

    /// Submit timeseries to the Metrics intake.
    ///
    /// - Parameter series: The timeseries.
    func submit(series: [Serie]) throws {
        var data = try series.reduce(Data()) { data, serie in
            try data + encoder.encode(serie) + separator
        }

        // remove last separator
        data.removeLast(separator.count)

        var request = URLRequest(url: intake)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "api-key": configuration.apiKey,
            "ATATUS-EVP-ORIGIN": "ios",
            "ATATUS-EVP-ORIGIN-VERSION": configuration.version,
            "ATATUS-REQUEST-ID": UUID().uuidString,
        ]

        request.httpBody = prefix + data + suffix
        session.dataTask(with: request).resume()
    }
}

private extension MetricExporter.MetricType {
    init(_ type: MetricDataType) {
        switch type {
        case .DoubleSum, .LongSum:
            self = .count
        case .LongGauge, .DoubleGauge:
            self = .gauge
        case .Summary, .Histogram, .ExponentialHistogram:
            self = .unspecified
        }
    }
}
