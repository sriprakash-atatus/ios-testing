/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddCore` -> `AtatusCore`, `ddInternal` ->
// `AtatusInternal`; renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import XCTest
import TestUtilities
import AtatusInternal
@testable import AtatusCore

class DataStoreFileWriterTests: XCTestCase {
    private var writer: DataStoreFileWriter! // swiftlint:disable:this implicitly_unwrapped_optional

    override func setUpWithError() throws {
        CreateTemporaryDirectory()
        writer = DataStoreFileWriter(
            file: try Directory(url: temporaryDirectory).createFile(named: "file")
        )
    }

    override func tearDown() {
        DeleteTemporaryDirectory()
    }

    func testWritingVersionAndData() throws {
        // When
        try writer.write(data: "value data".utf8Data, version: 3)

        // Then
        let expectedBytes: [UInt8] = [
            // version block:
            /* T: */ 0x00, 0x00, /* L: */ 0x02, 0x00, 0x00, 0x00, /* V: */ 0x03, 0x00, // 3
            // data block:
            /* T: */ 0x01, 0x00, /* L: */ 0x0A, 0x00, 0x00, 0x00, /* V: */ 0x76, 0x61, 0x6C, 0x75, 0x65, 0x20, 0x64, 0x61, 0x74, 0x61, // "value data"
        ]
        let actualBytes = [UInt8](try writer.file.read())
        XCTAssertEqual(expectedBytes, actualBytes)
    }

    func testWritingVersion() throws {
        XCTAssertNoThrow(try writer.write(data: .mockAny(), version: .min))
        XCTAssertNoThrow(try writer.write(data: .mockAny(), version: .max))
    }

    func testWritingData() throws {
        // When
        let maxLength = maxDataStoreTLVDataLength
        let min = Data()
        let max: Data = .mockRandom(ofSize: maxLength)
        let overflow: Data = .mockRandom(ofSize: maxLength + 1)

        // Then
        XCTAssertNoThrow(try writer.write(data: min, version: .mockAny()))
        XCTAssertNoThrow(try writer.write(data: max, version: .mockAny()))
        ATAssertThrowsError(try writer.write(data: overflow, version: .mockAny())) { (error: DataStoreFileWritingError) in
            ATAssertReflectionEqual(error, .failedToEncodeData(TLVBlockError.bytesLengthExceedsLimit(length: maxLength + 1, limit: maxLength)))
        }
    }
}
