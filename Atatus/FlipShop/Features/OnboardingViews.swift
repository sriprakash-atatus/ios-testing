/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            Color.brand
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)

                Text("FlipShop")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.top, 24)
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            onFinished()
        }
    }
}

struct OnboardingView: View {
    let onFinished: () -> Void
    @State private var currentPage = 0

    private let pages: [(title: String, subtitle: String, icon: String)] = [
        ("Discover Everything", "Shop millions of products from electronics to fashion.", "sparkles"),
        ("Lightning Fast Delivery", "Enjoy super-fast delivery right to your doorstep.", "bolt.fill"),
        ("Safe & Secure", "Pay with UPI, cards, net banking or cash on delivery.", "lock.shield.fill")
    ]

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button("Skip") {
                    onFinished()
                }
                .foregroundStyle(.secondary)
                .padding()
            }

            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 20) {
                        Image(systemName: pages[index].icon)
                            .font(.system(size: 80))
                            .foregroundStyle(Color.brand)
                            .padding(.bottom, 20)

                        Text(pages[index].title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(pages[index].subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())

            PrimaryButton(currentPage == pages.count - 1 ? "Get Started" : "Continue") {
                if currentPage == pages.count - 1 {
                    onFinished()
                } else {
                    withAnimation {
                        currentPage += 1
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
