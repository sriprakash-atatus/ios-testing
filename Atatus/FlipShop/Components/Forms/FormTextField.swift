/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI
import UIKit

/// A labelled text field with an optional icon, a reveal toggle for passwords, a character limit and
/// an inline error.
struct FormTextField: View {
    let title: String
    @Binding var text: String
    var prompt: String = ""
    var systemImage: String?
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false
    var characterLimit: Int?
    /// Shown in red under the field, and turns its border red.
    var error: String?
    /// Text fixed before the input, like "+91".
    var prefix: String?

    @FocusState private var isFocused: Bool
    @State private var isRevealed = false

    init(
        _ title: String,
        text: Binding<String>,
        prompt: String = "",
        systemImage: String? = nil,
        keyboard: UIKeyboardType = .default,
        contentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        isSecure: Bool = false,
        characterLimit: Int? = nil,
        error: String? = nil,
        prefix: String? = nil
    ) {
        self.title = title
        self._text = text
        self.prompt = prompt
        self.systemImage = systemImage
        self.keyboard = keyboard
        self.contentType = contentType
        self.autocapitalization = autocapitalization
        self.isSecure = isSecure
        self.characterLimit = characterLimit
        self.error = error
        self.prefix = prefix
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: Theme.Spacing.xs) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(isFocused ? Color.brand : Color.textTertiary)
                        .frame(width: 20)
                }
                if let prefix = prefix {
                    Text(prefix)
                        .foregroundStyle(Color.textSecondary)
                }

                Group {
                    if isSecure && !isRevealed {
                        SecureField(prompt, text: $text)
                    } else {
                        TextField(prompt, text: $text)
                    }
                }
                .focused($isFocused)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(isSecure || keyboard != .default)

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: 50)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isFocused || error != nil ? 1.5 : 1)
            )
            .animation(Theme.quickSpring, value: isFocused)

            if let error = error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.danger)
                    .transition(.opacity)
            }
        }
        .onChange(of: text) { _, newValue in
            if let limit = characterLimit, newValue.count > limit {
                text = String(newValue.prefix(limit))
            }
        }
    }

    private var borderColor: Color {
        if error != nil {
            return .danger
        }
        return isFocused ? .brand : Color.divider.opacity(0.7)
    }
}

/// A notice banner: an icon and a message on a tinted background.
struct InfoBanner: View {
    let message: String
    var systemImage: String = "info.circle.fill"
    var tint: Color = .brand

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.Spacing.sm)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }
}
