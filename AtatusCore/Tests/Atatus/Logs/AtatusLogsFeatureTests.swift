/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`, `ddLogs` -> `AtatusLogs`; renamed `dd*` types to `Atatus*`; renamed the `DD`
// symbol prefix to `AT`; renamed `clientToken` to `licenseKey`; renamed the `ddsource` / `ddtags` query
// parameters to `atatus_source` / `atatustags`; renamed the `DD-*` intake headers to their Atatus
// equivalents; rebranded the licence header.

import XCTest
import TestUtilities
@_spi(Internal)
import AtatusInternal

@testable import AtatusLogs
@testable import AtatusCore

class AtatusLogsFeatureTests: XCTestCase {
    override func setUp() {
        super.setUp()
        temporaryCoreDirectory.create()
        // ATCHG: Log uploads are gated on the Atatus logs heartbeat, which defaults to disabled.
        // Enable it so these tests exercise the request builder.
        LogsHeartbeatScheduler.setLogsAllowed(true)
    }

    override func tearDown() {
        LogsHeartbeatScheduler.setLogsAllowed(false)
        temporaryCoreDirectory.delete()
        super.tearDown()
    }

    // MARK: - HTTP Message

    func testItUsesExpectedHTTPMessage() throws {
        let randomApplicationName: String = .mockRandom(among: .alphanumerics)
        let randomApplicationVersion: String = .mockRandom()
        let randomSource: String = .mockRandom(among: .alphanumerics)
        let randomOrigin: String = .mockRandom(among: .alphanumerics)
        let randomSDKVersion: String = .mockRandom(among: .alphanumerics)
        let randomUploadURL: URL = .mockRandom()
        let randomClientToken: String = .mockRandom()
        let randomDeviceName: String = .mockRandom()
        let randomDeviceOSName: String = .mockRandom()
        let randomDeviceOSVersion: String = .mockRandom()
        let randomEncryption: DataEncryption? = Bool.random() ? DataEncryptionMock() : nil
        let randomBackgroundTasksEnabled: Bool = .mockRandom()
        let httpClient = HTTPClientMock(responseCode: 200)

        let core = AtatusCore(
            directory: temporaryCoreDirectory,
            dateProvider: SystemDateProvider(),
            initialConsent: .granted,
            performance: .combining(
                storagePerformance: .writeEachObjectToNewFileAndReadAllFiles,
                uploadPerformance: .veryQuick
            ),
            httpClient: httpClient,
            encryption: randomEncryption,
            contextProvider: .mockWith(
                context: .mockWith(
                    licenseKey: randomClientToken,
                    version: randomApplicationVersion,
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
            ),
            applicationVersion: randomApplicationVersion,
            maxBatchesPerUpload: .mockRandom(min: 1, max: 100),
            backgroundTasksEnabled: randomBackgroundTasksEnabled
        )

        // Given
        Logs.enable(with: .init(customEndpoint: randomUploadURL), in: core)

        // When
        let logger = Logger.create(in: core)
        logger.debug(.mockAny())
        core.flushAndTearDown()

        // Then
        let requests = httpClient.requestsSent()
        XCTAssertEqual(requests.count, 1)
        let request = try XCTUnwrap(requests.first)
        let requestURL = try XCTUnwrap(request.url)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertTrue(requestURL.absoluteString.starts(with: randomUploadURL.absoluteString + "?"))
        // ATCHG: the logs intake now also receives license_key, agent_name, agent_version and
        // app_name, so assert on the source parameter rather than the whole query string.
        XCTAssertEqual(
            URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "atatus_source" }?.value,
            randomSource
        )
        XCTAssertEqual(
            request.allHTTPHeaderFields?["User-Agent"],
            """
            \(randomApplicationName)/\(randomApplicationVersion) CFNetwork (\(randomDeviceName); \(randomDeviceOSName)/\(randomDeviceOSVersion))
            """
        )
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Encoding"], "deflate")
        XCTAssertEqual(request.allHTTPHeaderFields?["api-key"], randomClientToken)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN"], randomOrigin)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN-VERSION"], randomSDKVersion)
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-REQUEST-ID"]?.matches(regex: .uuidRegex), true)
    }

    // MARK: - HTTP Payload

    func testItUsesExpectedPayloadFormatForUploads() throws {
        let httpClient = HTTPClientMock(responseCode: 200)

        let core = AtatusCore(
            directory: temporaryCoreDirectory,
            dateProvider: SystemDateProvider(),
            initialConsent: .granted,
            performance: .combining(
                storagePerformance: StoragePerformanceMock(
                    maxFileSize: .max,
                    maxDirectorySize: .max,
                    maxFileAgeForWrite: .distantFuture, // write all events to single file,
                    minFileAgeForRead: StoragePerformanceMock.readAllFiles.minFileAgeForRead,
                    maxFileAgeForRead: StoragePerformanceMock.readAllFiles.maxFileAgeForRead,
                    maxObjectsInFile: 3, // write 3 spans to payload,
                    maxObjectSize: .max
                ),
                uploadPerformance: UploadPerformanceMock(
                    initialUploadDelay: 0.5, // wait enough until events are written,
                    minUploadDelay: 1,
                    maxUploadDelay: 1,
                    uploadDelayChangeRate: 0
                )
            ),
            httpClient: httpClient,
            encryption: nil,
            contextProvider: .mockAny(),
            applicationVersion: .mockAny(),
            maxBatchesPerUpload: .mockRandom(min: 1, max: 100),
            backgroundTasksEnabled: .mockAny()
        )

        // Given
        Logs.enable(with: .init(), in: core)

        let logger = Logger.create(in: core)
        logger.debug("log 1")
        logger.debug("log 2")
        logger.debug("log 3")
        core.flushAndTearDown()

        let requests = httpClient.requestsSent()
        XCTAssertEqual(requests.count, 1)
        let payload = try XCTUnwrap(requests.first?.decompressed().httpBody)

        // Expected payload format:
        // `[log1JSON,log2JSON,log3JSON]`

        XCTAssertEqual(payload.prefix(1).utf8String, "[", "payload should start with JSON array trait: `[`")
        XCTAssertEqual(payload.suffix(1).utf8String, "]", "payload should end with JSON array trait: `]`")

        // Expect payload to be an array of log JSON objects
        let logMatchers = try LogMatcher.fromArrayOfJSONObjectsData(payload)
        logMatchers[0].assertMessage(equals: "log 1")
        logMatchers[1].assertMessage(equals: "log 2")
        logMatchers[2].assertMessage(equals: "log 3")
    }
}
