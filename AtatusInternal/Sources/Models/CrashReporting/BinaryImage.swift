/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; rebranded the licence header.

import Foundation

/// Binary Image referenced in frames from `ATThread`.
public struct BinaryImage: Codable {
    public let libraryName: String
    public let uuid: String
    public let architecture: String
    public let isSystemLibrary: Bool
    public let loadAddress: String
    public let maxAddress: String

    public init(
        libraryName: String,
        uuid: String,
        architecture: String,
        isSystemLibrary: Bool,
        loadAddress: String,
        maxAddress: String
    ) {
        self.libraryName = libraryName
        self.uuid = uuid
        self.architecture = architecture
        self.isSystemLibrary = isSystemLibrary
        self.loadAddress = loadAddress
        self.maxAddress = maxAddress
    }

    // MARK: - Encoding

    enum CodingKeys: String, CodingKey {
        case libraryName = "name"
        case uuid = "uuid"
        case architecture = "arch"
        case isSystemLibrary = "is_system"
        case loadAddress = "load_address"
        case maxAddress = "max_address"
    }
}

extension BinaryImage: Equatable {}
