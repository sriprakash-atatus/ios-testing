/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Manages lines indentation for generating code.
public class BasePrinter {
    var output = ""

    public init() {}

    // MARK: - Indentation

    private(set) var indentationLevel: Int = 0

    private var currentIndentation: String {
        let indentation = "    "
        let indentations = (0..<indentationLevel).map { _ in indentation }
        return indentations.joined(separator: "")
    }

    // MARK: - Printing

    func reset() {
        output = ""
    }

    func writeLine(_ content: String) {
        output += currentIndentation + content + "\n"
    }

    func writeEmptyLine() {
        output += "\n"
    }

    func indentRight() {
        indentationLevel += 1
    }

    func indentLeft() {
        precondition(indentationLevel > 0, "Indentation level can't get negative.")
        indentationLevel = indentationLevel - 1
    }
}
