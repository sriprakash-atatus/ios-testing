/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import XCTest
import AtatusInternal

class BundleTypeTests: XCTestCase {
    func testiOSAppBundleType() {
        let bundle: Bundle = .mockWith(bundlePath: "bundle.path.app")
        let bundleType = BundleType(bundle: bundle)
        XCTAssertEqual(bundleType, .iOSApp)
    }

    func testiOSAppExtensionBundleType() {
        let bundle: Bundle = .mockWith(bundlePath: "bundle.path.appex")
        let bundleType = BundleType(bundle: bundle)
        XCTAssertEqual(bundleType, .iOSAppExtension)
    }
}
