/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

struct Toast: Identifiable, Equatable {
    enum Style: Equatable, Sendable {
        case success
        case info
        case warning
        case error

        var symbolName: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            }
        }
    }

    let id: UUID
    let message: String
    let style: Style
    let actionTitle: String?
    let action: (@MainActor () -> Void)?

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

/// The one snackbar the app shows at a time, like "Added to cart · View cart".
@MainActor
@Observable
final class ToastCenter {
    private(set) var current: Toast?

    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    func show(
        _ message: String,
        style: Toast.Style = .success,
        actionTitle: String? = nil,
        duration: TimeInterval = 2.8,
        action: (@MainActor () -> Void)? = nil
    ) {
        dismissTask?.cancel()
        let toast = Toast(id: UUID(), message: message, style: style, actionTitle: actionTitle, action: action)
        current = toast
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else {
                return
            }
            self?.dismiss(toastID: toast.id)
        }
    }

    func show(error: Error) {
        show(APIError.message(for: error), style: .error)
    }

    /// Runs the toast's action, then dismisses it.
    func performAction() {
        let action = current?.action
        dismiss()
        action?()
    }

    func dismiss() {
        dismissTask?.cancel()
        current = nil
    }

    private func dismiss(toastID: UUID) {
        if current?.id == toastID {
            current = nil
        }
    }
}
