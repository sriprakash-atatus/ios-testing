/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; renamed `dd*` members to `at*`; rebranded the licence header.

#if os(iOS)

import Foundation
import UIKit
import AtatusInternal

extension UIColor: AtatusExtended {}

private var identifierKey: UInt8 = 0

extension AtatusExtension where ExtendedType: UIColor {
    var identifier: String {
        if let hash = objc_getAssociatedObject(type, &identifierKey) as? String {
            return hash
        }

        let hash = String(hexString.dropFirst())
        objc_setAssociatedObject(type, &identifierKey, hash, .OBJC_ASSOCIATION_RETAIN)
        return hash
    }

    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1

        type.getRed(&r, green: &g, blue: &b, alpha: &a)

        let ri = Int16.atWithNoOverflow(round(r * 255))
        let gi = Int16.atWithNoOverflow(round(g * 255))
        let bi = Int16.atWithNoOverflow(round(b * 255))
        let ai = Int16.atWithNoOverflow(round(a * 255))

        var rstr = String(ri, radix: 16, uppercase: true)
        var gstr = String(gi, radix: 16, uppercase: true)
        var bstr = String(bi, radix: 16, uppercase: true)
        var astr = String(ai, radix: 16, uppercase: true)

        rstr = ri < 16 ? "0\(rstr)" : rstr
        gstr = gi < 16 ? "0\(gstr)" : gstr
        bstr = bi < 16 ? "0\(bstr)" : bstr
        astr = ai < 16 ? "0\(astr)" : astr

        return "#\(rstr)\(gstr)\(bstr)\(astr)"
    }
}

#endif
