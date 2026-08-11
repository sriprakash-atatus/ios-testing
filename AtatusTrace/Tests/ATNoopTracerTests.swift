/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`,
// `ddTrace` -> `AtatusTrace`; renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; repointed the intake host at the Atatus site; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal

@testable import AtatusTrace

class ATNoopTracerTests: XCTestCase {
    func testWhenUsingDDNoopTracerAPIs_itPrintsWarning() {
        let dd = AT.mockWith(logger: CoreLoggerMock())
        defer { dd.reset() }

        // Given
        let noop = ATNoopTracer()

        // When
        let context = ATSpanContext.mockAny()
        noop.inject(
            spanContext: context,
            writer: HTTPHeadersWriter(traceContextInjection: .sampled)
        )
        _ = noop.extract(reader: HTTPHeadersReader(httpHeaderFields: [:]))
        let root = noop.startRootSpan(operationName: "root operation").setActive()
        let child = noop.startSpan(operationName: "child operation")
        child.finish()
        root.finish()

        // Then
        let expectedWarningMessage = """
        The `AtatusTracer.shared()` was called but `AtatusTracer` is not initialised. Configure the `AtatusTracer` before invoking the feature:
            AtatusTracer.initialize()
        See https://www.atatus.com/docs/
        """

        XCTAssertEqual(dd.logger.warnLogs.count, 4)
        dd.logger.warnLogs.forEach { log in
            XCTAssertEqual(log.message, expectedWarningMessage)
        }
    }
}
