/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import SwiftUI

@available(iOS 13.0, *)
extension Image {
    public static var atatusLogo: Image {
        Image("dd_logo", bundle: .module)
    }

    public static var flowers: Image {
        Image("Flowers_1", bundle: .module)
    }
}
