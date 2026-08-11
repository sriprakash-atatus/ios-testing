/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed `dd*` types to `Atatus*`; rebranded the licence header.

import XCTest
import AtatusInternal
import TestUtilities
@testable import AtatusCore

private struct RemoteFeatureMock: AtatusRemoteFeature {
    static let name: String = "remote-feature-mock"

    var requestBuilder: FeatureRequestBuilder = FeatureRequestBuilderMock()
    var messageReceiver: FeatureMessageReceiver = NOPFeatureMessageReceiver()
    var performanceOverride: AtatusInternal.PerformancePresetOverride?
}

private struct FeatureMock: AtatusFeature {
    static let name: String = "feature-mock"

    var messageReceiver: FeatureMessageReceiver = NOPFeatureMessageReceiver()
}

class AtatusCore_FeatureDirectoriesTests: XCTestCase {
    private var core: AtatusCore! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUp() {
        super.setUp()
        temporaryCoreDirectory.create()
        core = AtatusCore(
            directory: temporaryCoreDirectory,
            dateProvider: SystemDateProvider(),
            initialConsent: .mockRandom(),
            performance: .mockRandom(),
            httpClient: HTTPClientMock(),
            encryption: nil,
            contextProvider: .mockAny(),
            applicationVersion: .mockAny(),
            maxBatchesPerUpload: .mockRandom(min: 1, max: 100),
            backgroundTasksEnabled: .mockAny()
        )
    }

        override func tearDownWithError() throws {
        core.flushAndTearDown()
        core = nil
        temporaryCoreDirectory.delete()
        super.tearDown()
    }

    func testWhenRegisteringRemoteFeature_itCreatesFeatureDirectories() throws {
        // When
        try core.register(feature: RemoteFeatureMock())

        // Then
        let featureDirectory = try temporaryCoreDirectory.coreDirectory.subdirectory(path: RemoteFeatureMock.name)
        XCTAssertNoThrow(try featureDirectory.subdirectory(path: "v2"), "Authorized data directory must exist")
        XCTAssertNoThrow(try featureDirectory.subdirectory(path: "intermediate-v2"), "Intermediate data directory must exist")
    }

    func testWhenRegisteringFeature_itDoesNotCreateFeatureDirectories() throws {
        // When
        try core.register(feature: FeatureMock())

        // Then
        XCTAssertThrowsError(
            try temporaryCoreDirectory.coreDirectory.subdirectory(path: FeatureMock.name),
            "Feature directory must not exist"
        )
    }
}
