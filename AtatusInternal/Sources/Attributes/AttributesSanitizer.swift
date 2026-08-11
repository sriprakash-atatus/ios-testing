/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed the `DD` symbol prefix to `AT`; rebranded the `dd` name to
// `Atatus` in comments and docs; rebranded the licence header.

import Foundation

/// Common attributes sanitizer for all features.
public struct AttributesSanitizer {
    public struct Constraints {
        /// Maximum number of nested levels in attribute name. E.g. `person.address.street` has 3 levels.
        /// If attribute name exceeds this number, extra levels are escaped by using `_` character (`one.two.(...).nine.ten_eleven_twelve`).
        public static let maxNestedLevelsInAttributeName: Int = 10
        /// Maximum number of attributes in log.
        /// If this number is exceeded, extra attributes will be ignored.
        public static let maxNumberOfAttributes: Int = 256
    }

    let featureName: String

    public init(featureName: String) {
        self.featureName = featureName
    }

    // MARK: - Attribute keys sanitization

    /// Attribute keys can only have `Constants.maxNestedLevelsInAttributeName` levels.
    /// Extra levels are escaped with "_", e.g.:
    ///
    ///     one.two.three.four.five.six.seven.eight.nine.ten.eleven
    ///
    /// becomes:
    ///
    ///     one.two.three.four.five.six.seven.eight_nine_ten_eleven
    ///
    public func sanitizeKeys<Value>(for attributes: [String: Value], prefixLevels: Int = 0) -> [String: Value] {
        let sanitizedAttributes: [(String, Value)] = attributes.map { key, value in
            let sanitizedName = sanitize(attributeKey: key, prefixLevels: prefixLevels)
            if sanitizedName != key {
                AT.logger.warn(
                    """
                    \(featureName) attribute '\(key)' was modified to '\(sanitizedName)' to match Atatus constraints.
                    """
                )
                return (sanitizedName, value)
            } else {
                return (key, value)
            }
        }
        return Dictionary(uniqueKeysWithValues: sanitizedAttributes)
    }

    private func sanitize(attributeKey: String, prefixLevels: Int = 0) -> String {
        var dotsCount = prefixLevels
        var sanitized = ""
        for char in attributeKey {
            if char == "." {
                dotsCount += 1
                sanitized.append(dotsCount >= Constraints.maxNestedLevelsInAttributeName ? "_" : char)
            } else {
                sanitized.append(char)
            }
        }
        return sanitized
    }

    // MARK: - Attributes count limitting

    /// Removes attributes exceeding the `count` limit.
    public func limitNumberOf<Value>(attributes: [String: Value], to count: Int) -> [String: Value] {
        if attributes.count > count {
            let extraAttributesCount = attributes.count - count
            AT.logger.warn(
                """
                Number of \(featureName) attributes exceeds the limit of \(Constraints.maxNumberOfAttributes).
                \(extraAttributesCount) attribute(s) will be ignored.
                """
            )
            return Dictionary(uniqueKeysWithValues: attributes.dropLast(extraAttributesCount))
        } else {
            return attributes
        }
    }
}
