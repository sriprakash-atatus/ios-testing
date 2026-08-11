/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal

/// The locale publisher will publish an updated ``LocaleInfo`` value with current locale properties
/// by observing the `NSCurrentLocaleDidChangeNotification` notification on the given
/// notification center.
internal final class LocaleInfoPublisher: ContextValuePublisher {
    let initialValue: LocaleInfo

    private let notificationCenter: NotificationCenter
    private var observer: Any?

    /// Creates a locale info publisher that updates locale information.
    ///
    /// - Parameters:
    ///   - initialLocale: The initial locale info.
    ///   - notificationCenter: The notification center for observing the `NSCurrentLocaleDidChangeNotification`.
    init(initialLocale: LocaleInfo, notificationCenter: NotificationCenter) {
        self.initialValue = initialLocale
        self.notificationCenter = notificationCenter
    }

    func publish(to receiver: @escaping ContextValueReceiver<LocaleInfo>) {
        self.observer = notificationCenter
            .addObserver(
                forName: NSLocale.currentLocaleDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                let updatedLocale = LocaleInfo()
                receiver(updatedLocale)
            }
    }

    func cancel() {
        observer.map(notificationCenter.removeObserver)
    }
}
