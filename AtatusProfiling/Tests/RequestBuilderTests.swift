/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddProfiling` -> `AtatusProfiling`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol
// prefix to `AT`; renamed `clientToken` to `licenseKey`; renamed the `ddsource` / `ddtags` query parameters
// to `atatus_source` / `atatustags`; renamed the `DD-*` intake headers to their Atatus equivalents;
// repointed the intake host at the Atatus site; rebranded the licence header.

#if !os(watchOS)
import XCTest
import AtatusInternal
import TestUtilities

@testable import AtatusProfiling

class RequestBuilderTests: XCTestCase {
    private let rumContext: RUMCoreContext = .mockRandom()

    let profileEvent = ProfileEvent(
        family: .mockRandom(),
        runtime: .mockRandom(),
        version: .mockRandom(),
        start: .mockRandomInThePast(),
        end: Date(),
        attachments: [],
        tags: .mockAny(),
        additionalAttributes: mockRandomAttributes()
    )

    let rumEvents: [RUMEvent] = [.vital(.mockWith(operationKey: nil, stepType: nil))]
    let pprof: Data = .mockRandom()

    private func mockEvent() throws -> Event {
        let encoder = JSONEncoder.dd.default()

        let rumEventsData = try encoder.encode(rumEvents)
        let attachments: ProfileAttachments = .init(pprof: pprof, rumEvents: rumEventsData)
        return try Event(
            data: encoder.encode(profileEvent),
            metadata: encoder.encode(attachments)
        )
    }

    func testItCreatesPOSTRequest() throws {
        // Given
        let builder = RequestBuilder(customUploadURL: nil, telemetry: TelemetryMock())

        // When
        let request = try builder.request(for: [mockEvent()], with: .mockAny(), execution: .mockAny())

        // Then
        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testItSetsIntakeURL() {
        // Given
        let builder = RequestBuilder(customUploadURL: nil, telemetry: TelemetryMock())

        // When
        func url(for site: AtatusSite) throws -> String {
            let request = try builder.request(for: [mockEvent()], with: .mockWith(site: site), execution: .mockAny())
            return request.url!.absoluteStringWithoutQuery!
        }

        // Then
        // ATCHG: single Atatus intake host replaces the nine dd region endpoints
        XCTAssertEqual(try url(for: .atatus), "https://mo-rx.atatus.com/api/v2/profile")
    }

    func testItSetsCustomIntakeURL() {
        // Given
        let randomURL: URL = .mockRandom()
        let builder = RequestBuilder(customUploadURL: randomURL, telemetry: TelemetryMock())

        // When
        func url(for site: AtatusSite) throws -> String {
            let request = try builder.request(for: [mockEvent()], with: .mockWith(site: site), execution: .mockAny())
            return request.url!.absoluteStringWithoutQuery!
        }

        // Then
        let expectedURL = randomURL.absoluteStringWithoutQuery
        // ATCHG: single Atatus site replaces the nine dd regions
        XCTAssertEqual(try url(for: .atatus), expectedURL)
    }

    func testItSetsQueryParameters() throws {
        // Given
        let builder = RequestBuilder(customUploadURL: nil, telemetry: TelemetryMock())
        let context: AtatusContext = .mockRandom()

        // When
        let request = try builder.request(for: [mockEvent()], with: context, execution: .mockWith(previousResponseCode: nil, attempt: 0))

        // Then
        XCTAssertNil(request.url!.query)
    }

    func testItSetsHTTPHeaders() throws {
        let randomApplicationName: String = .mockRandom(among: .alphanumerics)
        let randomVersion: String = .mockRandom(among: .decimalDigits)
        let randomSource: String = .mockRandom(among: .alphanumerics)
        let randomSDKVersion: String = .mockRandom(among: .alphanumerics)
        let randomClientToken: String = .mockRandom()
        let randomDeviceName: String = .mockRandom()
        let randomDeviceOSName: String = .mockRandom()
        let randomDeviceOSVersion: String = .mockRandom()

        // Given
        let builder = RequestBuilder(customUploadURL: nil, telemetry: TelemetryMock())
        let context: AtatusContext = .mockWith(
            licenseKey: randomClientToken,
            version: randomVersion,
            source: randomSource,
            sdkVersion: randomSDKVersion,
            applicationName: randomApplicationName,
            device: .mockWith(name: randomDeviceName),
            os: .mockWith(
                name: randomDeviceOSName,
                version: randomDeviceOSVersion
            )
        )

        // When
        let request = try builder.request(for: [mockEvent()], with: context, execution: .mockAny())

        // Then
        let contentType = try XCTUnwrap(request.allHTTPHeaderFields?["Content-Type"])
        XCTAssertTrue(contentType.matches(regex: #"multipart\/form-data; boundary=([0-9A-Fa-f]{8}(-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12})"#))
        XCTAssertEqual(
            request.allHTTPHeaderFields?["User-Agent"],
            """
            \(randomApplicationName)/\(randomVersion) CFNetwork (\(randomDeviceName); \(randomDeviceOSName)/\(randomDeviceOSVersion))
            """
        )
        XCTAssertEqual(request.allHTTPHeaderFields?["api-key"], randomClientToken)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN"], randomSource)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN-VERSION"], randomSDKVersion)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-REQUEST-ID"]?.matches(regex: .uuidRegex), true)
    }

    func testItSetsHTTPBodyInExpectedFormat() throws {
        // Given
        let event = try mockEvent()
        let multipartSpy = MultipartBuilderSpy()
        let builder = RequestBuilder(multipartBuilder: multipartSpy, customUploadURL: nil, telemetry: TelemetryMock())

        // When
        let request = try builder.request(for: [event], with: .mockAny(), execution: .mockAny())

        // Then
        let contentType = try XCTUnwrap(request.allHTTPHeaderFields?["Content-Type"])
        XCTAssertTrue(contentType.matches(regex: "multipart/form-data; boundary=\(multipartSpy.boundary)"))
        XCTAssertEqual(multipartSpy.formFiles.count, 3)

        let eventFile = multipartSpy.formFiles[0]
        XCTAssertEqual(eventFile.filename, "event.json")
        XCTAssertEqual(eventFile.mimeType, "application/json")
        XCTAssertEqual(eventFile.data, event.data)

        let pprofFile = multipartSpy.formFiles[1]
        XCTAssertEqual(pprofFile.filename, "wall.pprof")
        XCTAssertEqual(pprofFile.mimeType, "application/octet-stream")
        XCTAssertEqual(pprofFile.data, pprof)

        let rumEventsFile = multipartSpy.formFiles[2]
        XCTAssertEqual(rumEventsFile.filename, "rum-mobile-events.json")
        XCTAssertEqual(rumEventsFile.mimeType, "application/json")

        let encodedRUMEvents = try XCTUnwrap(JSONSerialization.jsonObject(with: rumEventsFile.data) as? [[String: Any]])
        let vitals = encodedRUMEvents.filter { $0["type"] as? String == "vital" }
        let vitalIDs = vitals.compactMap { $0["id"] as? String }
        let vitalNames = vitals.compactMap { $0["name"] as? String }
        let expectedVitalIDs = rumEvents.compactMap { event -> String? in
            guard case .vital(let vital) = event else {
                return nil
            }
            return vital.id
        }
        let expectedVitalNames = rumEvents.compactMap { event -> String? in
            guard case .vital(let vital) = event else {
                return nil
            }
            return vital.name
        }

        XCTAssertEqual(vitalIDs, expectedVitalIDs)
        XCTAssertEqual(vitalNames, expectedVitalNames)
    }

    func testWhenBatchDataHasMoreThanOneProfile() {
        // Given
        let builder = RequestBuilder(customUploadURL: nil, telemetry: TelemetryMock())

        // When, Then
        XCTAssertThrowsError(try builder.request(for: .mockAny(count: 2), with: .mockAny(), execution: .mockAny()))
    }

    func testWhenBatchDataIsMissingMetadata() {
        // Given
        let builder = RequestBuilder(customUploadURL: nil, telemetry: TelemetryMock())

        // When, Then
        XCTAssertThrowsError(try builder.request(
            for: [.mockWith(data: .mockRandom(), metadata: nil)],
            with: .mockAny(),
            execution: .mockAny()
        ))
    }

    func testItSetsRetryQueryParameters() throws {
        // Given
        let randomAttempt: UInt = .mockRandom(min: 1, max: 10)
        let randomStatus: Int = .mockRandom()
        let builder = RequestBuilder(customUploadURL: nil, telemetry: TelemetryMock())
        let execution: ExecutionContext = .mockWith(previousResponseCode: randomStatus, attempt: randomAttempt)

        // When
        let request = try builder.request(for: [mockEvent()], with: .mockRandom(), execution: execution)

        // Then
        XCTAssertEqual(request.url!.query, "atatustags=retry_count:\(randomAttempt),retry_after:\(randomStatus)")
    }

    func testItSetsRetryQueryParametersOnNetworkErrorRetry() throws {
        // Given
        let builder = RequestBuilder(customUploadURL: nil, telemetry: TelemetryMock())
        let execution: ExecutionContext = .mockWith(previousResponseCode: nil, attempt: 1) // network error retry has no response code

        // When
        let request = try builder.request(for: [mockEvent()], with: .mockRandom(), execution: execution)

        // Then
        XCTAssertEqual(request.url!.query, "atatustags=retry_count:1") // no retry_after without response code
    }
}
#endif // !os(watchOS)
