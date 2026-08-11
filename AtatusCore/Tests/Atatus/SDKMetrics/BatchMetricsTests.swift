/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`; rebranded the licence
// header.

import XCTest
@testable import AtatusCore

class BatchMetricsTests: XCTestCase {
    func testBatchRemovalReasonFormatting() {
        typealias RemovalReason = BatchDeletedMetric.RemovalReason

        XCTAssertEqual(RemovalReason.intakeCode(responseCode: 202).toString(), "intake-code-202")
        XCTAssertEqual(RemovalReason.obsolete.toString(), "obsolete")
        XCTAssertEqual(RemovalReason.purged.toString(), "purged")
        XCTAssertEqual(RemovalReason.invalid.toString(), "invalid")
        XCTAssertEqual(RemovalReason.flushed.toString(), "flushed")
    }

    func testOnlyCertainBatchRemovalReasonsAreIncludedInMetric() {
        typealias RemovalReason = BatchDeletedMetric.RemovalReason

        XCTAssertTrue(RemovalReason.intakeCode(responseCode: 202).includeInMetric)
        XCTAssertTrue(RemovalReason.obsolete.includeInMetric)
        XCTAssertTrue(RemovalReason.purged.includeInMetric)
        XCTAssertTrue(RemovalReason.invalid.includeInMetric)
        XCTAssertFalse(RemovalReason.flushed.includeInMetric)
    }
}
