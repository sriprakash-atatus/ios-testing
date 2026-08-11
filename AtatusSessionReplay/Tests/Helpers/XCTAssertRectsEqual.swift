/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation
import XCTest

func XCTAssertRectsEqual(
    _ rect1: CGRect,
    _ rect2: CGRect,
    accuracy: CGFloat,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(rect1.origin.x, rect2.origin.x, accuracy: accuracy, message, file: file, line: line)
    XCTAssertEqual(rect1.origin.y, rect2.origin.y, accuracy: accuracy, message, file: file, line: line)
    XCTAssertEqual(rect1.width, rect2.width, accuracy: accuracy, message, file: file, line: line)
    XCTAssertEqual(rect1.height, rect2.height, accuracy: accuracy, message, file: file, line: line)
}
