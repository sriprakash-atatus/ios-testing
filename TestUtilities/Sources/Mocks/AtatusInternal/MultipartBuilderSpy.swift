/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

import Foundation

@testable import AtatusInternal

public class MultipartBuilderSpy: MultipartFormDataBuilder {
    public var formFields: [String: String] = [:]
    public var formFiles: [(filename: String, data: Data, mimeType: String)] = []
    public var returnedData: Data = .mockRandom()

    public init() { }

    public let boundary: String = UUID().uuidString

    public func addFormField(name: String, value: String) { formFields[name] = value }

    public func addFormData(name: String, filename: String, data: Data, mimeType: String) {
        formFiles.append((filename: filename, data: data, mimeType: mimeType))
    }

    public func build() -> Data { returnedData }
}
