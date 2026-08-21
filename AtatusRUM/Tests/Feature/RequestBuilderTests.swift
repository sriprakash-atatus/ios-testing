/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`, `ddRUM`
// -> `AtatusRUM`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to `AT`; renamed
// `clientToken` to `licenseKey`; renamed the `ddsource` / `ddtags` query parameters to `atatus_source` /
// `atatustags`; renamed the `DD-*` intake headers to their Atatus equivalents; repointed the intake host at
// the Atatus site; moved the intake path to `/v1/ios/*`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@testable import AtatusRUM

class RequestBuilderTests: XCTestCase {
    private let mockEvents: [Event] = [
        .init(data: "event 1".utf8Data),
        .init(data: "event 2".utf8Data),
        .init(data: "event 3".utf8Data)
    ]

    func testItCreatesPOSTRequest() throws {
        // Given
        let builder = RequestBuilder(
            customIntakeURL: nil,
            eventsFilter: .init(telemetry: TelemetryMock()),
            telemetry: NOPTelemetry()
        )

        // When
        let request = try builder.request(for: mockEvents, with: .mockAny(), execution: .mockAny())

        // Then
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testItSetsRUMIntakeURL() {
        // Given
        let builder = RequestBuilder(
            customIntakeURL: nil,
            eventsFilter: .init(telemetry: TelemetryMock()),
            telemetry: NOPTelemetry()
        )

        // When
        func url(for site: AtatusSite) -> String {
            let request = try! builder.request(for: mockEvents, with: .mockWith(site: site), execution: .mockAny())
            return request.url!.absoluteStringWithoutQuery!
        }

        // Then
        // ATCHG: single Atatus intake host replaces the nine dd region endpoints
        XCTAssertEqual(url(for: .atatus), "https://mo-rx.atatus.com/v1/android/rum")
    }

    func testItSetsCustomIntakeURL() throws {
        // Given
        let randomURL: URL = .mockRandom()
        let builder = RequestBuilder(
            customIntakeURL: randomURL,
            eventsFilter: .init(telemetry: TelemetryMock()),
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

    func testItSetsRUMQueryParameters() throws {
        let randomSource: String = .mockRandom(among: .alphanumerics)
        let randomVersion: String = .mockRandom(among: .decimalDigits)
        let randomService: String = .mockRandom(among: .alphanumerics)
        let randomEnv: String = .mockRandom(among: .alphanumerics)
        let randomSDKVersion: String = .mockRandom(among: .alphanumerics)
        let randomAttempt: UInt = .mockRandom()
        let randomStatus: Int = .mockRandom()

        // Given
        let builder = RequestBuilder(
            customIntakeURL: nil,
            eventsFilter: .init(telemetry: TelemetryMock()),
            telemetry: NOPTelemetry()
        )
        let randomLicenseKey: String = .mockRandom(among: .alphanumerics)
        let randomAppName: String = .mockRandom(among: .alphanumerics)
        let context: AtatusContext = .mockWith(
            licenseKey: randomLicenseKey,
            service: randomService,
            env: randomEnv,
            version: randomVersion,
            appName: randomAppName,
            source: randomSource,
            sdkVersion: randomSDKVersion
        )
        let execution: ExecutionContext = .mockWith(previousResponseCode: randomStatus, attempt: randomAttempt)

        // When
        let request = try builder.request(for: mockEvents, with: context, execution: execution)

        // Then
        // ATCHG: The RUM intake now receives the Atatus query parameters (renamed `atatus_source`
        // and `atatustags`, plus `license_key`, `agent_name`, `agent_version` and `app_name`),
        // matching `buildUrl()` in Android's `RumRequestFactory`.
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false))
        let query = (components.queryItems ?? []).reduce(into: [String: String]()) { $0[$1.name] = $1.value }
        XCTAssertEqual(query["atatus_source"], randomSource)
        XCTAssertEqual(query["license_key"], randomLicenseKey)
        XCTAssertEqual(query["agent_name"], AgentInfo.agentName)
        XCTAssertEqual(query["agent_version"], AgentInfo.agentVersion)
        XCTAssertEqual(query["app_name"], randomAppName)
        XCTAssertEqual(query["atatustags"], "retry_count:\(randomAttempt),retry_after:\(randomStatus)")
        // ATCHG: End
    }

    func testItSetsRUMHTTPHeaders() throws {
        let randomApplicationName: String = .mockRandom(among: .alphanumerics)
        let randomVersion: String = .mockRandom(among: .decimalDigits)
        let randomService: String = .mockRandom(among: .alphanumerics)
        let randomEnv: String = .mockRandom(among: .alphanumerics)
        let randomSource: String = .mockRandom(among: .alphanumerics)
        let randomOrigin: String = .mockRandom(among: .alphanumerics)
        let randomSDKVersion: String = .mockRandom(among: .alphanumerics)
        let randomClientToken: String = .mockRandom()
        let randomDeviceName: String = .mockRandom()
        let randomDeviceOSName: String = .mockRandom()
        let randomDeviceOSVersion: String = .mockRandom()

        // Given
        let builder = RequestBuilder(
            customIntakeURL: nil,
            eventsFilter: .init(telemetry: TelemetryMock()),
            telemetry: NOPTelemetry()
        )
        let context: AtatusContext = .mockWith(
            licenseKey: randomClientToken,
            service: randomService,
            env: randomEnv,
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
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Encoding"], "deflate")
        XCTAssertEqual(request.allHTTPHeaderFields?["api-key"], randomClientToken)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN"], randomOrigin)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN-VERSION"], randomSDKVersion)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-REQUEST-ID"]?.matches(regex: .uuidRegex), true)
    }

    func testItSetsHTTPBodyInExpectedFormat() throws {
        // Given
        let builder = RequestBuilder(
            customIntakeURL: nil,
            eventsFilter: .init(telemetry: TelemetryMock()),
            telemetry: NOPTelemetry()
        )

        // When
        let request = try builder.request(for: mockEvents, with: .mockAny(), execution: .mockAny())

        // Then
        let decompressed = zlib.decode(request.httpBody!)!
        let actual = String(data: decompressed, encoding: .utf8)
        let expected = """
        event 1
        event 2
        event 3
        """
        XCTAssertEqual(expected, actual, "It must separate each event with newline character")
    }

    func testItSetsNoRetryQueryParametersOnFirstRequest() throws {
        // Given
        let randomSource: String = .mockRandom(among: .alphanumerics)
        let builder = RequestBuilder(customIntakeURL: nil, eventsFilter: .init(telemetry: TelemetryMock()), telemetry: NOPTelemetry())
        let context: AtatusContext = .mockWith(source: randomSource)
        let execution: ExecutionContext = .mockWith(previousResponseCode: nil, attempt: 0)

        // When
        let request = try builder.request(for: mockEvents, with: context, execution: execution)

        // Then
        // ATCHG: the Atatus identification parameters are always present; assert only that no retry tags are added
        let query = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)).queryItems ?? []
        XCTAssertEqual(query.first { $0.name == "atatus_source" }?.value, randomSource)
        XCTAssertNil(query.first { $0.name == "atatustags" }, "no atatustags on first request")
    }

    func testItSetsRetryQueryParametersOnNetworkErrorRetry() throws {
        // Given
        let randomSource: String = .mockRandom(among: .alphanumerics)
        let builder = RequestBuilder(customIntakeURL: nil, eventsFilter: .init(telemetry: TelemetryMock()), telemetry: NOPTelemetry())
        let context: AtatusContext = .mockWith(source: randomSource)
        let execution: ExecutionContext = .mockWith(previousResponseCode: nil, attempt: 1) // network error retry has no response code

        // When
        let request = try builder.request(for: mockEvents, with: context, execution: execution)

        // Then
        // ATCHG: the Atatus identification parameters are always present; assert the retry tags only
        let query = try XCTUnwrap(URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)).queryItems ?? []
        XCTAssertEqual(query.first { $0.name == "atatus_source" }?.value, randomSource)
        XCTAssertEqual(query.first { $0.name == "atatustags" }?.value, "retry_count:1", "no retry_after without response code")
    }
}
