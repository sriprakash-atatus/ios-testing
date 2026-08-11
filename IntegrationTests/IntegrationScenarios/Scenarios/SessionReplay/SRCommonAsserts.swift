/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; renamed `dd*` members to `at*`;
// renamed the `DD-*` intake headers to their Atatus equivalents; rebranded the licence header.

import HTTPServerMock
import TestUtilities
import XCTest

/// A set of common assertions for all RUM tests.
protocol SRCommonAsserts {
    func assertSR(requests: [HTTPServerMock.Request], file: StaticString, line: UInt)
}

extension SRCommonAsserts {
    func assertSR(
        requests: [HTTPServerMock.Request],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        requests.forEach { request in
            XCTAssertEqual(request.httpMethod, "POST")

            // Example path here: `/36882784-420B-494F-910D-CBAC5897A309`
            XCTAssertNotNil(request.path, file: file, line: line)

            let contentTypeRegex = #"^multipart/form-data; boundary=.*$"#
            XCTAssertEqual(request.httpHeaders["Content-Type"]?.matches(regex: contentTypeRegex), true, file: file, line: line)
            XCTAssertEqual(request.httpHeaders["User-Agent"]?.matches(regex: userAgentRegex), true, file: file, line: line)
            XCTAssertEqual(request.httpHeaders["api-key"], "ui-tests-client-token", file: file, line: line)
            XCTAssertEqual(request.httpHeaders["ATATUS-EVP-ORIGIN"], "ios", file: file, line: line)
            XCTAssertEqual(request.httpHeaders["ATATUS-EVP-ORIGIN-VERSION"]?.matches(regex: semverRegex), true, file: file, line: line)
            XCTAssertEqual(request.httpHeaders["ATATUS-REQUEST-ID"]?.matches(regex: atRequestIDRegex), true, file: file, line: line)
        }
    }
}

extension SRRequestMatcher {
    static func from(requests: [HTTPServerMock.Request]) throws -> [SRRequestMatcher] {
        try requests.map { try from(request: $0) }
    }

    static func from(request: HTTPServerMock.Request) throws -> SRRequestMatcher {
        try SRRequestMatcher(body: request.httpBody, headers: request.httpHeaders)
    }
}

extension SRSegmentMatcher {
    static func segmentsCount(from requests: [Request]) throws -> Int {
        try SRRequestMatcher.from(requests: requests).reduce(0) { total, request in
            let count = try request.blob { try JSONSerialization.jsonObject(with: $0, options: []) as? [Any] }?.count ?? 0
            return total + count
        }
    }
}
