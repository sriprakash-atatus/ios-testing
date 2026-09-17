/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation

struct AuthSession: Hashable, Codable, Sendable {
    let user: User
    let token: String
}

enum OTPPurpose: String, Codable, Sendable {
    case login
    case signUp
    case passwordReset

    var title: String {
        switch self {
        case .login: return "Verify your number"
        case .signUp: return "Verify your account"
        case .passwordReset: return "Reset your password"
        }
    }
}

/// A one-time code sent to the shopper, waiting to be entered.
struct OTPChallenge: Identifiable, Hashable, Codable, Sendable {
    static let codeLength = 6

    let id: String
    let purpose: OTPPurpose
    /// Where the code went, masked — "+91 98••• ••210".
    let destination: String
    let expiresAt: Date
    /// The account the code signs in or creates, once verified.
    let pendingUser: User?
}

protocol AuthServiceProtocol: Sendable {
    func login(email: String, password: String) async throws -> AuthSession
    func startPhoneLogin(phone: String) async throws -> OTPChallenge
    func startSignUp(name: String, email: String, phone: String, password: String) async throws -> OTPChallenge
    func startPasswordReset(email: String) async throws -> OTPChallenge
    /// Checks the code. Returns the new session for login and sign-up, and `nil` for a password reset.
    func verify(code: String, for challenge: OTPChallenge) async throws -> AuthSession?
    func resendCode(for challenge: OTPChallenge) async throws -> OTPChallenge
    func completePasswordReset(for challenge: OTPChallenge, newPassword: String) async throws
    func logout() async
}

/// Accepts any well-formed credentials. A few inputs fail on purpose so every error state is reachable:
/// the password `wrongpassword`, the email `taken@flipshop.app` at sign-up, and any code but `123456`.
struct MockAuthService: AuthServiceProtocol {
    static let demoEmail = "demo@flipshop.app"
    static let demoPassword = "Demo@1234"
    static let validCode = "123456"

    static let demoUser = User(
        id: "usr_demo",
        name: "Priya Sharma",
        email: demoEmail,
        phone: "9876543210",
        memberSince: Date(timeIntervalSince1970: 1_640_995_200),
        isPlusMember: true
    )

    func login(email: String, password: String) async throws -> AuthSession {
        try await MockNetwork.delay(0.6...1.2)
        guard Validator.isValidEmail(email) else {
            throw APIError.validation(message: "Enter a valid email address.")
        }
        guard password != "wrongpassword", password.count >= 6 else {
            throw APIError.unauthorized(message: "Incorrect email or password. Please try again.")
        }
        return AuthSession(user: user(forEmail: email), token: token())
    }

    func startPhoneLogin(phone: String) async throws -> OTPChallenge {
        try await MockNetwork.delay(0.5...1.0)
        guard Validator.isValidPhone(phone) else {
            throw APIError.validation(message: "Enter a valid 10-digit mobile number.")
        }
        var user = Self.demoUser
        user.phone = Validator.digits(in: phone)
        return challenge(.login, destination: Formatters.maskedPhone(phone), user: user)
    }

    func startSignUp(name: String, email: String, phone: String, password: String) async throws -> OTPChallenge {
        try await MockNetwork.delay(0.6...1.2)
        if email.lowercased() == "taken@flipshop.app" {
            throw APIError.validation(message: "An account with this email already exists. Try signing in instead.")
        }
        let user = User(
            id: "usr_\(UUID().uuidString.prefix(8).lowercased())",
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.lowercased(),
            phone: Validator.digits(in: phone),
            memberSince: Date(),
            isPlusMember: false
        )
        return challenge(.signUp, destination: Formatters.maskedPhone(phone), user: user)
    }

    func startPasswordReset(email: String) async throws -> OTPChallenge {
        try await MockNetwork.delay(0.5...1.0)
        guard Validator.isValidEmail(email) else {
            throw APIError.validation(message: "Enter a valid email address.")
        }
        return challenge(.passwordReset, destination: Formatters.maskedEmail(email), user: nil)
    }

    func verify(code: String, for challenge: OTPChallenge) async throws -> AuthSession? {
        try await MockNetwork.delay(0.5...1.0)
        guard challenge.expiresAt > Date() else {
            throw APIError.validation(message: "This code has expired. Request a new one.")
        }
        guard code == Self.validCode else {
            throw APIError.validation(message: "That code isn't right. Check the code and try again.")
        }
        guard challenge.purpose != .passwordReset, let user = challenge.pendingUser else {
            return nil
        }
        return AuthSession(user: user, token: token())
    }

    func resendCode(for challenge: OTPChallenge) async throws -> OTPChallenge {
        try await MockNetwork.delay(0.4...0.8)
        return self.challenge(challenge.purpose, destination: challenge.destination, user: challenge.pendingUser)
    }

    func completePasswordReset(for challenge: OTPChallenge, newPassword: String) async throws {
        try await MockNetwork.delay(0.6...1.0)
        guard Validator.isValidPassword(newPassword) else {
            throw APIError.validation(message: "Use at least 8 characters with a letter and a number.")
        }
    }

    func logout() async {
        try? await MockNetwork.delay(0.2...0.4)
    }

    private func user(forEmail email: String) -> User {
        if email.lowercased() == Self.demoEmail {
            return Self.demoUser
        }
        let localPart = email.split(separator: "@").first.map(String.init) ?? "Shopper"
        let name = localPart
            .split(whereSeparator: { $0 == "." || $0 == "_" || $0 == "-" })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
        return User(
            id: "usr_\(abs(email.lowercased().hashValue) % 1_000_000)",
            name: name.isEmpty ? "Shopper" : name,
            email: email.lowercased(),
            phone: "9876543210",
            memberSince: Date(),
            isPlusMember: false
        )
    }

    private func challenge(_ purpose: OTPPurpose, destination: String, user: User?) -> OTPChallenge {
        OTPChallenge(
            id: UUID().uuidString,
            purpose: purpose,
            destination: destination,
            expiresAt: Date().addingTimeInterval(10 * 60),
            pendingUser: user
        )
    }

    private func token() -> String {
        "mock_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}
