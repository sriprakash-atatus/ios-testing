/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct ToastView: View {
    let toast: Toast
    let onAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: toast.style.symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(iconColor)

            Text(toast.message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let actionTitle = toast.actionTitle {
                Button(actionTitle, action: onAction)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.brandAccent)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Color(white: 0.13), in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .padding(.horizontal, Theme.Spacing.md)
        .gesture(
            DragGesture(minimumDistance: 10).onEnded { value in
                if value.translation.height > 20 {
                    onDismiss()
                }
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private var iconColor: Color {
        switch toast.style {
        case .success: return .success
        case .info: return .brand
        case .warning: return .warning
        case .error: return .danger
        }
    }
}

extension View {
    /// Shows `ToastCenter`'s current toast above the bottom edge. Apply once, near the root.
    func toastOverlay() -> some View {
        modifier(ToastOverlayModifier())
    }
}

private struct ToastOverlayModifier: ViewModifier {
    @Environment(ToastCenter.self) private var toasts

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast = toasts.current {
                ToastView(toast: toast, onAction: { toasts.performAction() }, onDismiss: { toasts.dismiss() })
                    // Clears the tab bar.
                    .padding(.bottom, 64)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .id(toast.id)
            }
        }
        .animation(Theme.spring, value: toasts.current)
    }
}
