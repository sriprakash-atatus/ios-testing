/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

public final class MockNotificationCenter: NotificationCenter, @unchecked Sendable {
    private(set) var observers: [(name: Notification.Name?, object: Any?, queue: OperationQueue?, block: (Notification) -> Void)] = []

    override public func addObserver(forName name: Notification.Name?, object: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        let observer = NSObject()
        observers.append((name, object, queue, block))
        return observer
    }

    public func postFakeNotification(name: Notification.Name) {
        for observer in observers where observer.name == name {
            observer.block(Notification(name: name))
        }
    }

    public func getObserverNames() -> [Notification.Name] {
        observers.compactMap(\.name)
    }
}
