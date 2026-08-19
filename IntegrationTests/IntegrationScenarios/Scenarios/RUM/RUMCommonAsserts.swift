/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; renamed `dd*` members to `at*`;
// renamed the `ddsource` / `ddtags` query parameters to `atatus_source` / `atatustags`; renamed the `DD-*`
// intake headers to their Atatus equivalents; rebranded the licence header.

import TestUtilities
import HTTPServerMock
import XCTest

/// A set of common assertions for all RUM tests.
protocol RUMCommonAsserts {
    func assertRUM(requests: [HTTPServerMock.Request], file: StaticString, line: UInt)
}

extension RUMCommonAsserts {
    func assertRUM(
        requests: [HTTPServerMock.Request],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        requests.forEach { request in
            XCTAssertEqual(request.httpMethod, "POST")

            // Example path here: `/36882784-420B-494F-910D-CBAC5897A309?atatus_source=ios`
            XCTAssertNotNil(request.path, file: file, line: line)
            assertAtatusIdentificationQueryItems(in: request, file: file, line: line)

            XCTAssertEqual(request.httpHeaders["Content-Type"], "text/plain;charset=UTF-8", file: file, line: line)
            XCTAssertEqual(request.httpHeaders["User-Agent"]?.matches(regex: userAgentRegex), true, file: file, line: line)
            XCTAssertEqual(request.httpHeaders["api-key"], "ui-tests-client-token", file: file, line: line)
            XCTAssertEqual(request.httpHeaders["ATATUS-EVP-ORIGIN"], "ios", file: file, line: line)
            XCTAssertEqual(request.httpHeaders["ATATUS-EVP-ORIGIN-VERSION"]?.matches(regex: semverRegex), true, file: file, line: line)
            XCTAssertEqual(request.httpHeaders["ATATUS-REQUEST-ID"]?.matches(regex: atRequestIDRegex), true, file: file, line: line)
            XCTAssertEqual(request.httpHeaders["AT-IDEMPOTENCY-KEY"]?.matches(regex: sha1Regex), true, file: file, line: line)
        }
    }
}

extension RUMSessionMatcher {
    /// Retrieves single RUM Session from given `requests`.
    /// - Parameter eventsPatch: optional transformation to apply on each event within the payload before instantiating matcher (default: `nil`)
    class func singleSession(from requests: [HTTPServerMock.Request], eventsPatch: ((Data) throws -> Data)? = nil) throws -> RUMSessionMatcher? {
        return try sessions(maxCount: 1, from: requests, eventsPatch: eventsPatch).first
    }

    /// Retrieves `maxCount` RUM Sessions from given `requests`.
    /// - Parameter eventsPatch: optional transformation to apply on each event within the payload before instantiating matcher (default: `nil`)
    class func sessions(maxCount: Int, from requests: [HTTPServerMock.Request], eventsPatch: ((Data) throws -> Data)? = nil) throws -> [RUMSessionMatcher] {
        let eventMatchers = try requests
            .flatMap { request in try RUMEventMatcher.fromNewlineSeparatedJSONObjectsData(request.httpBody, eventsPatch: eventsPatch) }
            .filterTelemetry()
        let sessionMatchers = try RUMSessionMatcher.groupMatchersBySessions(eventMatchers).sorted(by: {
            return $0.views.first?.viewEvents.first?.date ?? 0 < $1.views.first?.viewEvents.first?.date ?? 0
        })

        if sessionMatchers.count > maxCount {
            throw Exception(
                description:
                """
                Expected to build \(maxCount) RUM Session(s) from given requests, but got \(sessionMatchers.count) instead.
                """
            )
        }

        return sessionMatchers
    }

    class func assertViewWasEventuallyInactive(_ view: View) {
        XCTAssertFalse(try XCTUnwrap(view.viewEvents.last?.view.isActive))
    }

    /// Checks if RUM session has ended by:
    /// - checking if it contains "end view" added in response to `ExampleApplication.endRUMSession()`;
    /// - checking if all other views are marked as "inactive" (meaning they ended up processing their resources).
    func hasEnded() -> Bool {
        let hasEndView = views.last?.name == Environment.Constants.rumSessionEndViewName
        let hasSomeActiveView = views.contains(where: { $0.viewEvents.last?.view.isActive == true })
        return hasEndView && !hasSomeActiveView
    }
}
