/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

#if os(iOS)

import Foundation
import AtatusInternal

extension StyledTextContentView: Reflection {
    init(from reflector: Reflector) throws {
        text = try reflector.descendant("text")
    }
}

extension ResolvedStyledText.StringDrawing: Reflection {
    init(from reflector: Reflector) throws {
        storage = try reflector.descendant("storage")
    }
}

#endif
