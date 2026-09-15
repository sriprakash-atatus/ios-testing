/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

enum AuthState: Equatable, Sendable {
    case signedOut
    case guest
    case signedIn(User)
}

/// Onboarding, sign-in and the signed-in user.
@MainActor
@Observable
final class SessionStore {
    private(set) var authState: AuthState = .signedOut
    private(set) var hasCompletedOnboarding: Bool

    @ObservationIgnored private let service: any AuthServiceProtocol
    @ObservationIgnored private let userService: any UserServiceProtocol
    @ObservationIgnored private let persistence: PersistenceStore
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var token: String?

    private static let onboardingKey = "flipshop.hasCompletedOnboarding"
    private static let guestKey = "flipshop.isBrowsingAsGuest"

    init(
        service: any AuthServiceProtocol,
        userService: any UserServiceProtocol,
        persistence: PersistenceStore = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userService = userService
        self.persistence = persistence
        self.defaults = defaults
        hasCompletedOnboarding = defaults.bool(forKey: SessionStore.onboardingKey)

        if let session = persistence.load(AuthSession.self, for: .session) {
            authState = .signedIn(session.user)
            token = session.token
        } else if defaults.bool(forKey: SessionStore.guestKey) {
            authState = .guest
        }
    }

    // MARK: - Reading

    var user: User? {
        if case .signedIn(let user) = authState {
            return user
        }
        return nil
    }

    var isSignedIn: Bool { user != nil }
    var isGuest: Bool { authState == .guest }
    /// Signed in or browsing as a guest — either way, past the sign-in screen.
    var hasSession: Bool { authState != .signedOut }
    var displayName: String { user?.firstName ?? "Guest" }

    // MARK: - Onboarding

    func completeOnboarding() {
        hasCompletedOnboarding = true
        defaults.set(true, forKey: SessionStore.onboardingKey)
    }

    /// Shows onboarding again on the next launch.
    func resetOnboarding() {
        hasCompletedOnboarding = false
        defaults.set(false, forKey: SessionStore.onboardingKey)
    }

    // MARK: - Signing in

    func continueAsGuest() {
        authState = .guest
        defaults.set(true, forKey: SessionStore.guestKey)
    }

    func login(email: String, password: String) async throws {
        start(try await service.login(email: email, password: password))
    }

    func startPhoneLogin(phone: String) async throws -> OTPChallenge {
        try await service.startPhoneLogin(phone: phone)
    }

    func startSignUp(name: String, email: String, phone: String, password: String) async throws -> OTPChallenge {
        try await service.startSignUp(name: name, email: email, phone: phone, password: password)
    }

    func startPasswordReset(email: String) async throws -> OTPChallenge {
        try await service.startPasswordReset(email: email)
    }

    /// Checks the code. Signs in when it completes a login or sign-up; returns whether it did.
    @discardableResult
    func verify(code: String, for challenge: OTPChallenge) async throws -> Bool {
        guard let session = try await service.verify(code: code, for: challenge) else {
            return false
        }
        start(session)
        return true
    }

    func resendCode(for challenge: OTPChallenge) async throws -> OTPChallenge {
        try await service.resendCode(for: challenge)
    }

    func completePasswordReset(for challenge: OTPChallenge, newPassword: String) async throws {
        try await service.completePasswordReset(for: challenge, newPassword: newPassword)
    }

    // MARK: - Account

    func updateProfile(name: String, email: String, phone: String) async throws {
        guard var user = user else {
            throw APIError.unauthorized(message: "Sign in to edit your profile.")
        }
        user.name = name.trimmingCharacters(in: .whitespaces)
        user.email = email.trimmingCharacters(in: .whitespaces).lowercased()
        user.phone = Validator.digits(in: phone)
        let updated = try await userService.updateProfile(user)
        start(AuthSession(user: updated, token: token ?? ""))
    }

    func logout() async {
        await service.logout()
        authState = .signedOut
        token = nil
        persistence.remove(.session)
        defaults.set(false, forKey: SessionStore.guestKey)
    }

    private func start(_ session: AuthSession) {
        authState = .signedIn(session.user)
        token = session.token
        persistence.save(session, for: .session)
        defaults.set(false, forKey: SessionStore.guestKey)
    }
}
