/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

#if os(iOS)
import UIKit

private var sessionReplaySlotIDKey: UInt8 = 0

extension UIView: AtatusExtended {}

@_spi(Internal)
public extension AtatusExtension where ExtendedType: UIView {
    /// Identifies this view as a host slot for embedded Session Replay content.
    ///
    /// The slot ID is supplied by the embedding SDK and is independent of the view's wireframe ID.
    var sessionReplaySlotID: String? {
        objc_getAssociatedObject(type, &sessionReplaySlotIDKey) as? String
    }

    /// Sets the Session Replay slot ID for this view.
    ///
    /// Changing the slot changes the recorded view hierarchy, so this triggers a new snapshot.
    @available(iOS 13.0, tvOS 13.0, *)
    @MainActor
    func setSessionReplaySlotID(_ slotID: String?) {
        guard slotID != sessionReplaySlotID else {
            return
        }

        objc_setAssociatedObject(
            type,
            &sessionReplaySlotIDKey,
            slotID,
            .OBJC_ASSOCIATION_COPY_NONATOMIC
        )

        // Changing the slot changes the recorded view hierarchy, so trigger a new snapshot.
        type.setNeedsLayout()
    }
}
#endif
