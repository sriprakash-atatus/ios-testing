/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`; rebranded the licence
// header.

import XCTest
import TestUtilities
@testable import AtatusCore

class DataStore_TLVTests: XCTestCase {
    /// The Length bytes for tested block.
    private let expectedL = Data([0x64, 0x00, 0x00, 0x00]) // "100" encoded as hex
    /// The Value bytes for tested block.
    private let expectedV: Data = .mockRandom(ofSize: 100) // 100 bytes of data

    func testSerializeVersionBlock() throws {
        // When
        let tlvData = try DataStoreBlock(type: .version, data: expectedV).serialize()

        // Then
        let expectedT = Data([0x00, 0x00])
        XCTAssertEqual(tlvData, expectedT + expectedL + expectedV)
    }

    func testSerializeDataBlock() throws {
        // When
        let tlvData = try DataStoreBlock(type: .data, data: expectedV).serialize()

        // Then
        let expectedT = Data([0x01, 0x00])
        XCTAssertEqual(tlvData, expectedT + expectedL + expectedV)
    }
}
