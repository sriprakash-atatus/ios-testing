/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed the `DD` symbol prefix to `AT`; renamed `dd*` members to `at*`; renamed
// `clientToken` to `licenseKey`; renamed the `ddsource` / `ddtags` query parameters to `atatus_source` /
// `atatustags`; renamed the `DD-*` intake headers to their Atatus equivalents; rebranded the licence
// header.

import XCTest
import AtatusInternal
@testable import AtatusCore

class RequestBuilderTests: XCTestCase {
    // MARK: - Request URL

    func testBuildingRequestWithURLAndQueryItems() throws {
        let randomURL: URL = .mockRandom()
        let builder = URLRequestBuilder(
            url: randomURL,
            queryItems: [.atatusSource(source: "abc"), .atatusTags(tags: ["abc:def"])],
            headers: .mockRandom()
        )
        let request = builder.uploadRequest(with: .mockRandom())
        XCTAssertEqual(request.url?.absoluteString, "\(randomURL.absoluteString)?atatus_source=abc&atatustags=abc:def")
    }

    func testWhenBuildingRequestWithURLAndQueryItems_itEscapesWhitespacesInQuery() throws {
        let randomURL: URL = .mockRandom()
        let builder = URLRequestBuilder(
            url: randomURL,
            queryItems: [.atatusSource(source: "source with whitespace"), .atatusTags(tags: ["tag with whitespace"])],
            headers: .mockRandom()
        )
        let request = builder.uploadRequest(with: .mockRandom())
        XCTAssertEqual(request.url?.absoluteString, "\(randomURL.absoluteString)?atatus_source=source%20with%20whitespace&atatustags=tag%20with%20whitespace")
    }

    // MARK: - Request Headers

    func testBuildingRequestWithContentTypeHeader() {
        var builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: [.contentTypeHeader(contentType: .textPlainUTF8)])
        var request = builder.uploadRequest(with: .mockAny())
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "text/plain;charset=UTF-8")

        builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: [.contentTypeHeader(contentType: .applicationJSON)])
        request = builder.uploadRequest(with: .mockAny())
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json")

        builder = URLRequestBuilder(
            url: .mockRandom(),
            queryItems: .mockRandom(),
            headers: [.contentTypeHeader(contentType: .multipartFormData(boundary: "boundary-uuid"))]
        )
        request = builder.uploadRequest(with: .mockAny())
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "multipart/form-data; boundary=boundary-uuid")
    }

    func testBuildingRequestWithUserAgentHeader() {
        let builder = URLRequestBuilder(
            url: .mockRandom(),
            queryItems: .mockRandom(),
            headers: [
                .userAgentHeader(
                    appName: "FoobarApp",
                    appVersion: "1.2.3",
                    device: .mockWith(name: "iPhone"),
                    os: .mockWith(
                        name: "iOS",
                        version: "13.3.1"
                    )
                )
            ]
        )
        let request = builder.uploadRequest(with: .mockRandom())
        XCTAssertEqual(request.allHTTPHeaderFields?["User-Agent"], "FoobarApp/1.2.3 CFNetwork (iPhone; iOS/13.3.1)")
    }

    func testBuildingRequestWithComplexUserAgentHeader() {
        let builder = URLRequestBuilder(
            url: .mockRandom(),
            queryItems: .mockRandom(),
            headers: [
                .userAgentHeader(
                    appName: "Foobar 電話 𝛼β",
                    appVersion: "1.2.3",
                    device: .mockWith(name: "iPhone"),
                    os: .mockWith(
                        name: "iOS",
                        version: "13.3.1"
                    )
                )
            ]
        )
        let request = builder.uploadRequest(with: .mockRandom())
        XCTAssertEqual(request.allHTTPHeaderFields?["User-Agent"], "Foobar/1.2.3 CFNetwork (iPhone; iOS/13.3.1)")
    }

    func testBuildingRequestWithDDAPIKeyHeader() {
        let randomClientToken: String = .mockRandom()
        let builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: [.atAPIKeyHeader(licenseKey: randomClientToken)])
        let request = builder.uploadRequest(with: .mockRandom())
        XCTAssertEqual(request.allHTTPHeaderFields?["api-key"], randomClientToken)
    }

    func testBuildingRequestWithDDEVPOriginHeader() {
        let randomSource: String = .mockRandom()
        let builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: [.atEVPOriginHeader(source: randomSource)])
        let request = builder.uploadRequest(with: .mockRandom())
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN"], randomSource)
    }

    func testBuildingRequestWithDDEVPOriginVersionHeader() {
        let randomSDKVersion: String = .mockRandom()
        let builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: [.atEVPOriginVersionHeader(sdkVersion: randomSDKVersion)])
        let request = builder.uploadRequest(with: .mockRandom())
        XCTAssertEqual(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN-VERSION"], randomSDKVersion)
    }

    func testBuildingRequestWithDDRequestIDHeader() throws {
        let builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: [.atRequestIDHeader()])

        let request1 = builder.uploadRequest(with: .mockRandom())
        let request2 = builder.uploadRequest(with: .mockRandom())
        let request3 = builder.uploadRequest(with: .mockRandom())

        let requestID1 = try XCTUnwrap(request1.allHTTPHeaderFields?["ATATUS-REQUEST-ID"])
        let requestID2 = try XCTUnwrap(request2.allHTTPHeaderFields?["ATATUS-REQUEST-ID"])
        let requestID3 = try XCTUnwrap(request3.allHTTPHeaderFields?["ATATUS-REQUEST-ID"])

        let allIDs = Set([requestID1, requestID2, requestID3])
        XCTAssertEqual(allIDs.count, 3, "Each `ATATUS-REQUEST-ID` must produce unique ID")
        allIDs.forEach { id in
            XCTAssertTrue(id.matches(regex: .uuidRegex), "Each `ATATUS-REQUEST-ID` must be an UUID string")
        }
    }

    func testBuildingRequestWithMultipleHeaders() {
        let builder = URLRequestBuilder(
            url: .mockRandom(),
            queryItems: .mockRandom(),
            headers: [
                .contentTypeHeader(contentType: .textPlainUTF8),
                .userAgentHeader(appName: .mockAny(), appVersion: .mockAny(), device: .mockAny(), os: .mockAny()),
                .atAPIKeyHeader(licenseKey: .mockAny()),
                .atEVPOriginHeader(source: .mockAny()),
                .atEVPOriginVersionHeader(sdkVersion: .mockAny()),
                .atRequestIDHeader(),
            ]
        )

        let request = builder.uploadRequest(with: .mockAny())
        XCTAssertNotNil(request.allHTTPHeaderFields?["Content-Type"])
        XCTAssertNotNil(request.allHTTPHeaderFields?["Content-Encoding"])
        XCTAssertNotNil(request.allHTTPHeaderFields?["User-Agent"])
        XCTAssertNotNil(request.allHTTPHeaderFields?["api-key"])
        XCTAssertNotNil(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN"])
        XCTAssertNotNil(request.allHTTPHeaderFields?["ATATUS-EVP-ORIGIN-VERSION"])
        XCTAssertNotNil(request.allHTTPHeaderFields?["ATATUS-REQUEST-ID"])
        XCTAssertEqual(request.allHTTPHeaderFields?.count, 7)
    }

    // MARK: - Request Method

    func testItUsesPOSTMethodForProducedRequest() {
        let builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: .mockRandom())
        let request = builder.uploadRequest(with: .mockRandom())
        XCTAssertEqual(request.httpMethod, "POST")
    }

    // MARK: - Request Data

    func testWhenBuildingRequestWithDataAndCompression_thenItDeflatesHTTPBody() throws {
        // Given
        let builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: .mockRandom())

        for i in 2...8 { // Test from 100KB to 100MB
            // When
            let size = UInt64(pow(10, Double(i)))
            let randomData: Data = .mock(ofSize: size)
            let request = builder.uploadRequest(with: randomData, compress: true)
            let body = try XCTUnwrap(request.httpBody)

            // Then
            XCTAssertNotNil(request.allHTTPHeaderFields?["Content-Encoding"])
            XCTAssertLessThan(body.count, Int(size), "HTTP body must be compressed")
        }
    }

    func testWhenBuildingRequestWithSmallDataAndCompression_thenItDoesNotDeflateHTTPBody() throws {
        // When
        // In the worst possible case, where  deflate would expand the data,
        // deflation falls back to stored (uncompressed) data.
        let size = 8 // Small data will most likely inflate with zlib.
        let randomData: Data = .mock(ofSize: size)
        let builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: .mockRandom())

        let request = builder.uploadRequest(with: randomData, compress: true)
        let body = try XCTUnwrap(request.httpBody)

        // Then
        XCTAssertNil(request.allHTTPHeaderFields?["Content-Encoding"])
        XCTAssertEqual(body.count, Int(size), "HTTP body must not be alterated")
        XCTAssertEqual(body, randomData)
    }

    func testWhenBuildingRequestWithDataAndNoCompression_thenItDoesNotDeflatesHTTPBody() throws {
        // Given
        let builder = URLRequestBuilder(url: .mockRandom(), queryItems: .mockRandom(), headers: .mockRandom())

        // When
        let randomData: Data = .mockRandom()
        let request = builder.uploadRequest(with: randomData, compress: false)

        // Then
        let body = try XCTUnwrap(request.httpBody)
        XCTAssertNil(request.allHTTPHeaderFields?["Content-Encoding"])
        XCTAssertEqual(body, randomData, "HTTP body must not be compressed")
    }
}
