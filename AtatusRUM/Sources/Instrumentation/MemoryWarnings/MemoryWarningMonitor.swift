/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation
import AtatusInternal
import UIKit

/// Tracks the memory warnings history and publishes it to the subscribers.
internal final class MemoryWarningMonitor {
    let notificationCenter: NotificationCenter
    let reporter: MemoryWarningReporting

    init(
        memoryWarningReporter: MemoryWarningReporting,
        notificationCenter: NotificationCenter
    ) {
        self.notificationCenter = notificationCenter
        self.reporter = memoryWarningReporter
    }

    /// Starts monitoring memory warnings by subscribing to `UIApplication.didReceiveMemoryWarningNotification`.
    func start() {
        #if os(watchOS)
        consolePrint("Memory warnings instrumentation is not available on watchOS.", .warn)
        #else
        notificationCenter.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        #endif
    }

    @objc
    func didReceiveMemoryWarning() {
        reporter.reportMemoryWarning()
    }

    /// Stops monitoring memory warnings.
    func stop() {
        notificationCenter.removeObserver(self)
    }
}
