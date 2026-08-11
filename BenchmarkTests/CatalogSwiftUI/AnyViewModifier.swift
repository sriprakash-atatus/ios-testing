/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import SwiftUI

public struct AnyViewModifier: ViewModifier {
    private let _body: (Content) -> AnyView

    public init<Body: View>(@ViewBuilder body: @escaping (Content) -> Body) {
        self._body = { AnyView(body($0)) }
    }

    public init() {
        self._body = { AnyView($0) }
    }

    public func body(content: Content) -> some View {
        _body(content)
    }
}
