/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - rebranded the licence header.

import XCTest
@testable import CodeGeneration

final class SwiftTypeTests: XCTestCase {
    func testSwiftStructProperty_mutabilityLevelOrder() {
        let immutable = SwiftStruct.Property.Mutability.immutable.rawValue
        let mutableInternally = SwiftStruct.Property.Mutability.mutableInternally.rawValue
        let mutable = SwiftStruct.Property.Mutability.mutable.rawValue

        // The level order of property mutability must always be
        // .immutable < .mutableInternally < .mutable
        XCTAssertTrue(immutable < mutableInternally)
        XCTAssertTrue(mutableInternally < mutable)
    }
}
