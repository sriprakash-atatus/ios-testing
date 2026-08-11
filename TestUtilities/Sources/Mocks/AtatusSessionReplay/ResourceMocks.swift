/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddSessionReplay` -> `AtatusSessionReplay`;
// rebranded the licence header.

#if os(iOS)
import Foundation
@testable import AtatusSessionReplay

extension EnrichedResource: RandomMockable, AnyMockable {
    public static func mockAny() -> EnrichedResource {
        return .init(
            identifier: .mockAny(),
            data: .mockAny(),
            mimeType: .mockAny(),
            context: .mockAny()
        )
    }

    public static func mockWith(
        identifier: String = .mockAny(),
        data: Data = .mockAny(),
        mimeType: String = .mockAny(),
        context: Context = .mockAny()
    ) -> EnrichedResource {
        return .init(
            identifier: identifier,
            data: data,
            mimeType: mimeType,
            context: context
        )
    }

    public static func mockRandom() -> Self {
        return .init(
            identifier: .mockRandom(),
            data: .mockRandom(),
            mimeType: .mockRandom(),
            context: .mockRandom()
        )
    }
}

extension EnrichedResource.Context: RandomMockable, AnyMockable {
    public static func mockAny() -> AtatusSessionReplay.EnrichedResource.Context {
        return .init(
            .mockAny()
        )
    }

    public static func mockRandom() -> Self {
        return .init(
            .mockRandom()
        )
    }
}
#endif
