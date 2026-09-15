/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

extension View {
    /// A padded, rounded card on `Color.surface` with a soft shadow.
    func cardStyle(padding: CGFloat = Theme.Spacing.md, radius: CGFloat = Theme.Radius.md) -> some View {
        self
            .padding(padding)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .subtleShadow()
    }

    /// The app's one shadow: barely there in light mode, off in dark mode where it would read as a smudge.
    func subtleShadow() -> some View {
        modifier(SubtleShadowModifier())
    }

    /// The grouped grey behind scrolling screens, edge to edge.
    func screenBackground() -> some View {
        background(Color.appBackground.ignoresSafeArea())
    }

    /// A moving highlight across the view, for skeletons.
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
}

private struct SubtleShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 8, x: 0, y: 3)
    }
}

private struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = -1

    @ViewBuilder
    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width * 1.6)
                    }
                    .allowsHitTesting(false)
                }
                .clipped()
                .onAppear {
                    withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

/// Shrinks slightly while pressed — for cards and tiles that act as buttons.
struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(Theme.quickSpring, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
}
