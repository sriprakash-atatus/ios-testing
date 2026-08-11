/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; renamed `dd*` members to `at*`;
// renamed the `ddsource` / `ddtags` query parameters to `atatus_source` / `atatustags`; renamed the `DD-*`
// intake headers to their Atatus equivalents; rebranded the licence header.

import HTTPServerMock
import TestUtilities
import XCTest

/// A set of common assertions for all Logging tests.
protocol LoggingCommonAsserts {
    func assertLogging(requests: [HTTPServerMock.Request], file: StaticString, line: UInt)
}

extension LoggingCommonAsserts {
    func assertLogging(
        requests: [HTTPServerMock.Request],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        requests.forEach { request in
            XCTAssertEqual(request.httpMethod, "POST")

            // Example path here: `/36882784-420B-494F-910D-CBAC5897A309?atatus_source=ios`
            XCTAssertNotNil(request.path, file: file, line: line)
            XCTAssertNotNil(request.queryItems)
            XCTAssertEqual(request.queryItems!.count, 1)
            XCTAssertEqual(request.queryItems?.value(name: "atatusSource"), "ios", file: file, line: line)

            let atatusTags = request.queryItems?.atatusTags()
            XCTAssertNil(atatusTags, file: file, line: line)

            XCTAssertEqual(request.httpHeaders["Content-Type"], "application/json", file: file, line: line)
            XCTAssertEqual(request.httpHeaders["User-Agent"]?.matches(regex: userAgentRegex), true, file: file, line: line)
            XCTAssertEqual(request.httpHeaders["api-key"], "ui-tests-client-token", file: file, line: line)
            XCTAssertEqual(request.httpHeaders["ATATUS-EVP-ORIGIN"], "ios", file: file, line: line)
            XCTAssertEqual(request.httpHeaders["ATATUS-EVP-ORIGIN-VERSION"]?.matches(regex: semverRegex), true, file: file, line: line)
            XCTAssertEqual(request.httpHeaders["ATATUS-REQUEST-ID"]?.matches(regex: atRequestIDRegex), true, file: file, line: line)
        }
    }
}

extension LogMatcher {
    public class func from(requests: [HTTPServerMock.Request]) throws -> [LogMatcher] {
        return try requests
            .flatMap { request in try LogMatcher.fromArrayOfJSONObjectsData(request.httpBody) }
    }
}
