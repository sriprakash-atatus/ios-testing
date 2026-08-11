/*
* Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
* This product includes software developed at Atatus (https://www.atatus.com/).
* Copyright 2026-Present Atatus, Inc.
*/

// ATCHG: Atatus SDK migration - rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

import Foundation
import OpenTelemetryApi

extension Dictionary where Key == String, Value == OpenTelemetryApi.AttributeValue {
    /// Converts OpenTelemetry attributes to Atatus tags. This method is recursive
    /// and will flatten nested attributes. Collection attributes are flattened to multiple
    /// tags with `key.index` naming convention. If attribute value is an empty collection,
    /// it will be converted to empty string.
    var tags: [String: String] {
        var tags: [String: String] = [:]
        for (key, value) in self {
            switch value {
            case .bool(let value):
                tags[key] = value.description
            case .string(let value):
                tags[key] = value
            case .int(let value):
                tags[key] = value.description
            case .double(let value):
                tags[key] = value.description
            case .stringArray(let array):
                if array.isEmpty {
                    tags[key] = ""
                } else {
                    for (index, element) in array.enumerated() {
                        tags["\(key).\(index)"] = element
                    }
                }
            case .boolArray(let array):
                if array.isEmpty {
                    tags[key] = ""
                } else {
                    for (index, element) in array.enumerated() {
                        tags["\(key).\(index)"] = element.description
                    }
                }
            case .intArray(let array):
                if array.isEmpty {
                    tags[key] = ""
                } else {
                    for (index, element) in array.enumerated() {
                        tags["\(key).\(index)"] = element.description
                    }
                }
            case .doubleArray(let array):
                if array.isEmpty {
                    tags[key] = ""
                } else {
                    for (index, element) in array.enumerated() {
                        tags["\(key).\(index)"] = element.description
                    }
                }
            case .set(let set):
                if set.labels.tags.isEmpty {
                    tags[key] = ""
                } else {
                    for (nestedKey, nestedValue) in set.labels.tags {
                        tags["\(key).\(nestedKey)"] = nestedValue
                    }
                }
            case .array(let array):
                if array.values.isEmpty {
                    tags[key] = ""
                } else {
                    for (index, element) in array.values.enumerated() {
                        tags["\(key).\(index)"] = element.description
                    }
                }
            @unknown default:
                break
            }
        }
        return tags
    }
}
