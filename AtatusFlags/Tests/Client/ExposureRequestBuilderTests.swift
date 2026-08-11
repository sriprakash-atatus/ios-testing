/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddFlags` -> `AtatusFlags`, `ddInternal`
// -> `AtatusInternal`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`;
// renamed `clientToken` to `licenseKey`; renamed the `ddsource` / `ddtags` query parameters to
// `atatus_source` / `atatustags`; renamed the `DD-*` intake headers to their Atatus equivalents; repointed
// the intake host at the Atatus site; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusFlags

final class ExposureRequestBuilderTests: XCTestCase {
    private let mockEvents: [Event] = [
        .init(data: "event 1".utf8Data),
        .init(data: "event 2".utf8Data),
        .init(data: "event 3".utf8Data)
    ]

    func testItCreatesPOSTRequest() throws {
        // Given
        let builder = ExposureRequestBuilder(
            customIntakeURL: nil,
            telemetry: NOPTelemetry()
        )

        // When
        let request = try builder.request(for: mockEvents, with: .mockAny(), execution: .mockAny())

        // Then
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testItSetsExposuresIntakeURL() {
        // Given
        let builder = ExposureRequestBuilder(
            customIntakeURL: nil,
            telemetry: NOPTelemetry()
        )

        // When
        func url(for site: AtatusSite) -> String {
            let request = try! builder.request(for: mockEvents, with: .mockWith(site: site), execution: .mockAny())
            return request.url!.absoluteStringWithoutQuery!
        }

        // Then
        // ATCHG: single Atatus intake host replaces the nine dd region endpoints
        XCTAssertEqual(url(for: .atatus), "https://mo-rx.atatus.com/api/v2/exposures")
    }

    func testItSetsCustomIntakeURL() throws {
        // Given
        let randomURL: URL = .mockRandom()
        let builder = ExposureRequestBuilder(
            customIntakeURL: randomURL,
            telemetry: NOPTelemetry()
        )

        // When
        func url(for site: AtatusSite) -> String {
            let request = try! builder.request(for: mockEvents, with: .mockWith(site: site), execution: .mockAny())
            return request.url!.absoluteStringWithoutQuery!
        }

        // Then
        let expectedURL = randomURL.absoluteStringWithoutQuery
        // ATCHG: single Atatus site replaces the nine dd regions
        XCTAssertEqual(url(for: .atatus), expectedURL)
    }

    func testItSetsExposureQueryParameters() throws {
        let randomSource: String = .mockRandom(among: .alphanumerics)

        // Given
        let builder = ExposureRequestBuilder(
            customIntakeURL: nil,
            telemetry: NOPTelemetry()
        )
        let context: AtatusContext = .mockWith(source: randomSource)

        // When
        let request = try builder.request(for: mockEvents, with: context, execution: .mockAny())

        // Then
        let expectedQuery = "atatus_source=\(randomSource)"
        XCTAssertEqual(request.url?.query, expectedQuery)
    }

    func testItSetsExposureHTTPHeaders() throws {
        let randomApplicationName: String = .mockRandom(among: .alphanumerics)
        let randomVersion: String = .mockRandom(among: .decimalDigits)
        let randomSource: String = .mockRandom(among: .alphanumerics)
        let randomOrigin: String = .mockRandom(among: .alphanumerics)
        let randomSDKVersion: String = .mockRandom(among: .alphanumerics)
        let randomClientToken: String = .mockRandom()
        let randomDeviceName: String = .mockRandom()
        let randomDeviceOSName: String = .mockRandom()
        let randomDeviceOSVersion: String = .mockRandom()

        // Given
        let builder = ExposureRequestBuilder(
            customIntakeURL: nil,
            telemetry: NOPTelemetry()
        )
        let context: AtatusContext = .mockWith(
            licenseKey: randomClientToken,
            version: randomVersion,
            source: randomSource,
            sdkVersion: randomSDKVersion,
            ciAppOrigin: randomOrigin,
            applicationName: randomApplicationName,
            device: .mockWith(name: randomDeviceName),
            os: .mockWith(
                name: randomDeviceOSName,
                version: randomDeviceOSVersion
            )
        )

        // When
        let request = try builder.request(for: mockEvents, with: context, execution: .mockAny())

        // Then
        XCTAssertEqual(
            request.allHTTPHeaderFields?["User-Agent"],
            """
            \(randomApplicationName)/\(randomVersion) CFNetwork (\(randomDeviceName); \(randomDeviceOSName)/\(randomDeviceOSVersion))
            """
        )
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "text/plain;charset=UTF-8")
        XCTAssertEqual(request.allHTTPHeaderFields?["api-key"], randomClientToken)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN"], randomOrigin)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN-VERSION"], randomSDKVersion)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-REQUEST-ID"]?.matches(regex: .uuidRegex), true)
    }

    func testItSetsHTTPBodyInExpectedFormat() throws {
        // Given
        let builder = ExposureRequestBuilder(
            customIntakeURL: nil,
            telemetry: NOPTelemetry()
        )

        // When
        let request = try builder.request(for: mockEvents, with: .mockAny(), execution: .mockAny())

        // Then
        let httpBodyData = try XCTUnwrap(request.httpBody)
        let actual = String(data: httpBodyData, encoding: .utf8)
        let expected = """
        event 1
        event 2
        event 3
        """
        XCTAssertEqual(expected, actual, "It must separate each event with newline character")
    }
}
