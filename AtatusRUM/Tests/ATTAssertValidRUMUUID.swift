/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; scrubbed the remaining `dd`
// name to `dd` in comments and docs; rebranded the licence header.

import Foundation
import TestUtilities

func ATTAssertValidRUMUUID(_ uuid: @autoclosure () throws -> String?, _ message: @autoclosure () -> String = "", file: StaticString = #fileID, line: UInt = #line) {
    _DDEvaluateAssertion(message: message(), file: file, line: line) {
        try _DDTAssertValidRUMUUID(uuid())
    }
}

private func _DDTAssertValidRUMUUID(_ uuid: String?) throws {
    let schemaReference = "given by https://github.com/dd/rum-events-format/blob/master/schemas/_common-schema.json"
    guard let uuid = uuid else {
        throw ATAssertError.expectedFailure("`nil` is not valid RUM UUID \(schemaReference)")
    }

    let regex = #"^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$"#

    if uuid.range(of: regex, options: .regularExpression, range: nil, locale: nil) == nil {
        throw ATAssertError.expectedFailure("\(uuid) is not valid RUM UUID - it doesn't match \(regex) \(schemaReference)")
    }
}
