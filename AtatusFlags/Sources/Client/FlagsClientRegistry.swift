/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed the
// `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation
import AtatusInternal

internal final class FlagsClientRegistry {
    @ReadWriteLock
    private var clients: [String: FlagsClientProtocol] = [:]

    func register(_ client: FlagsClientProtocol, named name: String) {
        guard !isRegistered(clientName: name) else {
            AT.logger.warn("A flags client with name \(name) has already been registered.")
            return
        }
        clients[name] = client
    }

    func isRegistered(clientName: String) -> Bool {
        clients[clientName] != nil
    }

    @discardableResult
    func unregisterClient(named name: String) -> FlagsClientProtocol? {
        clients.removeValue(forKey: name)
    }

    func client(named name: String) -> FlagsClientProtocol? {
        clients[name]
    }
}
