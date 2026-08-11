/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities
@testable import AtatusCore

class FeatureContextTests: XCTestCase {
    func testFeatureContextSharing() throws {
        // Given
        let core = AtatusCore(
            directory: temporaryCoreDirectory,
            dateProvider: SystemDateProvider(),
            initialConsent: .granted,
            performance: .mockAny(),
            httpClient: HTTPClientMock(),
            encryption: nil,
            contextProvider: .mockAny(),
            applicationVersion: .mockAny(),
            maxBatchesPerUpload: .mockRandom(min: 1, max: 100),
            backgroundTasksEnabled: .mockAny()
        )

        defer { temporaryCoreDirectory.delete() }

        struct ContextMock: AdditionalContext {
            static let key: String = "test"
            let attribute: [String: String]
        }

        // When
        let attributes = ["key": "value"]
        core.set(context: ContextMock(attribute: attributes))

        // Then
        let context = core.contextProvider.read()
        XCTAssertEqual(context.additionalContext(ofType: ContextMock.self)?.attribute, attributes)
    }
}
