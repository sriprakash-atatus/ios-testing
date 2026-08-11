/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

#if os(iOS)
import UIKit

/// A publisher that publishes the screen brightness level from UIScreen.
internal final class BrightnessLevelPublisher: ContextValuePublisher {
    /// The initial brightness level.
    let initialValue: BrightnessLevel?

    /// The notification center to observe brightness changes.
    private let notificationCenter: NotificationCenter
    private let screen: UIScreen
    private var observers: [Any]? = nil

    init(notificationCenter: NotificationCenter = .default, screen: UIScreen = .main) {
        self.notificationCenter = notificationCenter
        self.screen = screen
        self.initialValue = Float(screen.brightness)
    }

    /// Publishes the brightness level to the given receiver.
    ///
    /// - Parameter receiver: The receiver to publish the brightness level to.
    func publish(to receiver: @escaping ContextValueReceiver<BrightnessLevel?>) {
        let block = { (notification: Notification) in
            receiver(Float(self.screen.brightness))
        }

        observers = [
            notificationCenter.addObserver(
                forName: UIScreen.brightnessDidChangeNotification,
                object: nil,
                queue: .main,
                using: block
            )
        ]

        receiver(initialValue)
    }

    func cancel() {
        observers?.forEach(notificationCenter.removeObserver)
        observers = nil
    }
}

#endif
