/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

#if os(iOS)
import AtatusInternal
import UIKit

@available(iOS 13.0, tvOS 13.0, *)
internal struct ImageSnapshotResource: Resource {
    let image: UIImage

    var mimeType: String {
        "image/png"
    }

    func calculateIdentifier() -> String {
        image.dd.identifier
    }

    func calculateData() -> Data {
        image.dd.pngData() ?? Data()
    }
}
#endif
