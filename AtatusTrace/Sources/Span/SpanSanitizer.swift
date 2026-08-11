/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// `dd` name to `Atatus` in comments and docs; rebranded the licence header.

import Foundation
import AtatusInternal

/// Sanitizes `SpanEvent` representation received from the user, so it can match Atatus APM constraints.
internal struct SpanSanitizer {
    private let attributesSanitizer = AttributesSanitizer(featureName: "Span")

    func sanitize(span: SpanEvent) -> SpanEvent {
        // Sanitize attribute names
        var sanitizedUserExtraInfo = attributesSanitizer.sanitizeKeys(for: span.userInfo.extraInfo)
        var sanitizedAccountExtraInfo: [String: String] = [:]
        if let accountInfoExtraInfo = span.accountInfo?.extraInfo {
            sanitizedAccountExtraInfo = attributesSanitizer.sanitizeKeys(for: accountInfoExtraInfo)
        }
        var sanitizedTags = attributesSanitizer.sanitizeKeys(for: span.tags)

        // Limit to max number of attributes
        // If any attributes need to be removed, we first reduce number of
        // span tags, then user info extra attributes.
        sanitizedUserExtraInfo = attributesSanitizer.limitNumberOf(
            attributes: sanitizedUserExtraInfo,
            to: AttributesSanitizer.Constraints.maxNumberOfAttributes
        )
        sanitizedAccountExtraInfo = attributesSanitizer.limitNumberOf(
            attributes: sanitizedAccountExtraInfo,
            to: AttributesSanitizer.Constraints.maxNumberOfAttributes - sanitizedUserExtraInfo.count
        )
        sanitizedTags = attributesSanitizer.limitNumberOf(
            attributes: sanitizedTags,
            to: AttributesSanitizer.Constraints.maxNumberOfAttributes - sanitizedAccountExtraInfo.count - sanitizedUserExtraInfo.count
        )

        var sanitizedSpan = span
        sanitizedSpan.userInfo.extraInfo = sanitizedUserExtraInfo
        sanitizedSpan.accountInfo?.extraInfo = sanitizedAccountExtraInfo
        sanitizedSpan.tags = sanitizedTags
        return sanitizedSpan
    }
}
