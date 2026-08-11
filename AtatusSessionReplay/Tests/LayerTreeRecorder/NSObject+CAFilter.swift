/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

#if os(iOS)
import Foundation

@available(iOS 13.0, tvOS 13.0, *)
extension NSObject {
    static func makeCAFilter(type: String) throws -> NSObject {
        guard
            let filterClass = NSClassFromString("CAFilter"),
            let filter = (filterClass as AnyObject).perform(
                NSSelectorFromString("filterWithType:"),
                with: type
            )?
            .takeUnretainedValue() as? NSObject
        else {
            struct CAFilterNotFound: Error {}
            throw CAFilterNotFound()
        }

        filter.perform(NSSelectorFromString("setDefaults"))
        return filter
    }
}
#endif
