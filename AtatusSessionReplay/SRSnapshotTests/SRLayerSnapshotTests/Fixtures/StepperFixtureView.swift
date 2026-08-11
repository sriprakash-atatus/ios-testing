/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import SwiftUI

internal struct StepperFixtureView: View {
    var body: some View {
        VStack {
            Stepper("Right enabled", value: .constant(0), in: 0...4)
            Stepper("Left enabled", value: .constant(4), in: 0...4)
            Stepper("Both enabled", value: .constant(3), in: 0...4)
            Stepper("Both disabled", value: .constant(0), in: 0...0)
        }
        .padding()
    }
}
