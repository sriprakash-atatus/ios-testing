/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; renamed `dd*` members to `at*`;
// renamed the build `variant` to `appName`; rebranded the licence header.

import Foundation

/// Shared key names used in `atTags` strings across the SDK.
public enum ATTag {
    public static let service = "service"
    public static let version = "version"
    public static let sdkVersion = "sdk_version"
    public static let env = "env"
    // ATCHG: Renamed the `variant` tag key to `app_name`, matching `LogAttributes.VARIANT`,
    // `RumAttributes.VARIANT` and `APPLICATION_VARIANT_KEY` in the Atatus Android agent.
    public static let appName = "app_name"
    // ATCHG: End

    /// Merges two `atTags` strings by key, e.g. `"service:app,env:prod"`.
    ///
    /// If a key exists in both `lhs` and `rhs`, the value from `rhs` takes precedence.
    ///
    /// - Parameters:
    ///   - lhs: The base `atTags` string.
    ///   - rhs: The `atTags` string to merge on top of `lhs`, if any.
    /// - Returns: The merged `atTags` string.
    public static func merge(_ lhs: String, with rhs: String?) -> String {
        guard let rhs, !rhs.isEmpty else {
            return lhs
        }

        return parse(lhs)
            .merging(parse(rhs)) { $1 }
            .map { "\($0.key):\($0.value)" }
            .sorted()
            .joined(separator: ",")
    }

    private static func parse(_ tags: String) -> [String: String] {
        tags
            .split(separator: ",")
            .compactMap { tag -> (key: String, value: String)? in
                let keyValue = tag.split(separator: ":", maxSplits: 1)
                guard keyValue.count == 2 else {
                    return nil
                }
                return (key: String(keyValue[0]), value: String(keyValue[1]))
            }
            .reduce(into: [:]) { result, tag in
                result[tag.key] = String(tag.value)
            }
    }
}
