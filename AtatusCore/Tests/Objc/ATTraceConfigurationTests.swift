/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddTrace` -> `AtatusTrace`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest
import TestUtilities
@_spi(objc)
import AtatusInternal
@_spi(objc)
@testable import AtatusTrace

class ATTraceConfigurationTests: XCTestCase {
    private var objc = objc_TraceConfiguration()
    private var swift: Trace.Configuration { objc.swiftConfig }

    func testSampleRate() {
        objc.sampleRate = 30
        XCTAssertEqual(objc.sampleRate, 30)
        XCTAssertEqual(swift.sampleRate, 30)
    }

    func testService() {
        objc.service = "custom-service"
        XCTAssertEqual(objc.service, "custom-service")
        XCTAssertEqual(swift.service, "custom-service")
    }

    func testTags() {
        let random: [String: Any] = mockRandomAttributes()
        objc.tags = random
        ATAssertJSONEqual(objc.tags!, random)
        ATAssertReflectionEqual(swift.tags!, random.dd.swiftAttributes)
    }

    func testSetDDTraceURLSessionTracking() {
        var tracking: objc_TraceURLSessionTracking

        tracking = objc_TraceURLSessionTracking(firstPartyHostsTracing: .init(hosts: ["foo.com"]))
        objc.setURLSessionTracking(tracking)
        ATAssertReflectionEqual(swift.urlSessionTracking, .init(firstPartyHostsTracing: .trace(hosts: ["foo.com"])))

        tracking = objc_TraceURLSessionTracking(firstPartyHostsTracing: .init(hosts: ["foo.com"], sampleRate: 99))
        objc.setURLSessionTracking(tracking)
        ATAssertReflectionEqual(swift.urlSessionTracking, .init(firstPartyHostsTracing: .trace(hosts: ["foo.com"], sampleRate: 99)))

        tracking = objc_TraceURLSessionTracking(firstPartyHostsTracing: .init(hostsWithHeaderTypes: ["foo.com": [.b3, .atatus]]))
        objc.setURLSessionTracking(tracking)
        ATAssertReflectionEqual(swift.urlSessionTracking, .init(firstPartyHostsTracing: .traceWithHeaders(hostsWithHeaders: ["foo.com": [.b3, .atatus]])))

        tracking = objc_TraceURLSessionTracking(firstPartyHostsTracing: .init(hostsWithHeaderTypes: ["foo.com": [.b3, .atatus]], sampleRate: 99))
        objc.setURLSessionTracking(tracking)
        ATAssertReflectionEqual(swift.urlSessionTracking, .init(firstPartyHostsTracing: .traceWithHeaders(hostsWithHeaders: ["foo.com": [.b3, .atatus]], sampleRate: 99)))
    }

    func testBundleWithRUM() {
        let random: Bool = .mockRandom()
        objc.bundleWithRumEnabled = random
        XCTAssertEqual(objc.bundleWithRumEnabled, random)
        XCTAssertEqual(swift.bundleWithRumEnabled, random)
    }

    func testSendNetworkInfo() {
        let random: Bool = .mockRandom()
        objc.networkInfoEnabled = random
        XCTAssertEqual(objc.networkInfoEnabled, random)
        XCTAssertEqual(swift.networkInfoEnabled, random)
    }

    func testCustomEndpoint() {
        let random: URL = .mockRandom()
        objc.customEndpoint = random
        XCTAssertEqual(objc.customEndpoint, random)
        XCTAssertEqual(swift.customEndpoint, random)
    }
}
