/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the licence header.

#if os(iOS)
import Foundation
import AtatusInternal

/// Runs scheduled work when the screen changes.
///
/// It uses `ScreenChangeMonitor` to detect layer display, draw, and layout
/// changes, then runs scheduled operations at most once per minimum interval.
/// This avoids waking the recorder when nothing visual changed.
internal final class ScreenChangeScheduler: Scheduler {
    let queue: Queue = MainQueue()

    private let minimumInterval: TimeInterval
    private let telemetry: Telemetry
    private let timerScheduler: any TimerScheduler

    private var monitor: ScreenChangeMonitor?
    private var operations: [() -> Void] = []

    init(
        minimumInterval: TimeInterval,
        telemetry: Telemetry,
        timerScheduler: any TimerScheduler = .dispatchSource
    ) {
        self.minimumInterval = minimumInterval
        self.telemetry = telemetry
        self.timerScheduler = timerScheduler
    }

    func schedule(operation: @escaping () -> Void) {
        queue.run {
            self.operations.append(operation)
        }
    }

    func start() {
        queue.run {
            guard self.monitor == nil else {
                return // already started
            }

            do {
                let monitor = try ScreenChangeMonitor(
                    minimumDeliveryInterval: self.minimumInterval,
                    timerScheduler: self.timerScheduler
                ) { [weak self] changeset in
                    self?.screenDidChange(changeset)
                }
                monitor.start()
                self.monitor = monitor
            } catch {
                self.telemetry.error("[SR] Could not create ScreenChangeMonitor", error: error)
            }
        }
    }

    func stop() {
        queue.run {
            guard let monitor = self.monitor else {
                return
            }
            monitor.stop()
            self.monitor = nil
        }
    }

    private func screenDidChange(_ changeset: CALayerChangeset) {
        // ScreenChangeMonitor notifies on the main thread
        AT.logger.debug("Screen changed: \(changeset)")
        operations.forEach { $0() }
    }
}
#endif
