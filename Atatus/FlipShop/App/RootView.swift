/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

/// Splash, then onboarding on first launch, then sign-in unless there is a session, then the shop.
struct RootView: View {
    private enum Phase {
        case splash
        case onboarding
        case auth
        case main
    }

    /// What account data depends on: who is signed in, and whether the catalog it's built from has loaded.
    private struct AccountDataKey: Equatable {
        let userID: String?
        let hasSession: Bool
        let catalogReady: Bool
    }

    @Environment(SessionStore.self) private var session
    @Environment(AccountStore.self) private var account
    @Environment(CatalogStore.self) private var catalog
    @Environment(OrderStore.self) private var orders
    @Environment(AppRouter.self) private var router
    @Environment(ToastCenter.self) private var toasts

    @State private var phase: Phase = .splash
    /// A link opened before the shop was showing, handled once it is.
    @State private var pendingURL: URL?

    var body: some View {
        @Bindable var router = router

        ZStack {
            switch phase {
            case .splash:
                SplashView(onFinished: finishSplash)
                    .transition(.opacity)
            case .onboarding:
                OnboardingView(onFinished: finishOnboarding)
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            case .auth:
                AuthFlowView(isDismissable: false)
                    .transition(.opacity)
            case .main:
                MainTabView()
                    .transition(.opacity)
                    .fullScreenCover(item: $router.cover) { cover in
                        AppCoverView(cover: cover)
                            .toastOverlay()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
        .toastOverlay()
        .preferredColorScheme(account.appearance.colorScheme)
        .task {
            await catalog.loadIfNeeded()
        }
        .task(id: AccountDataKey(userID: session.user?.id, hasSession: session.hasSession, catalogReady: catalog.hasContent)) {
            await loadAccountData()
        }
        .onChange(of: session.authState) { oldState, newState in
            handleAuthChange(from: oldState, to: newState)
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .main, let url = pendingURL {
                pendingURL = nil
                router.handle(url: url)
            }
        }
        .onOpenURL { url in
            if phase == .main {
                if !router.handle(url: url) {
                    toasts.show("That link couldn't be opened", style: .warning)
                }
            } else {
                pendingURL = url
            }
        }
    }

    // MARK: - Launch flow

    private func finishSplash() {
        if !session.hasCompletedOnboarding {
            phase = .onboarding
        } else {
            phase = session.hasSession ? .main : .auth
        }
    }

    private func finishOnboarding() {
        session.completeOnboarding()
        phase = session.hasSession ? .main : .auth
    }

    private func handleAuthChange(from oldState: AuthState, to newState: AuthState) {
        switch newState {
        case .signedIn(let user):
            if router.cover == .auth {
                router.dismissCover()
            }
            if phase == .auth {
                phase = .main
            }
            if oldState != .signedIn(user) {
                toasts.show("Welcome, \(user.firstName)!")
            }
        case .guest:
            if phase == .auth {
                phase = .main
            }
        case .signedOut:
            account.reset()
            orders.reset()
            router.cover = nil
            AppTab.allCases.forEach { router.popToRoot($0) }
            router.selectedTab = .home
            if phase == .main {
                phase = .auth
            }
        }
    }

    private func loadAccountData() async {
        guard session.hasSession else {
            return
        }
        await account.load(for: session.user)
        if session.isSignedIn && catalog.hasContent {
            await orders.loadIfNeeded(for: session.user, catalog: catalog.products)
        }
    }
}
