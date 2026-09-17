/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import SwiftUI

/// A section title with an optional subtitle, icon and "See All".
struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var systemImage: String?
    var iconColor: Color = .brand
    var actionTitle: String = "See All"
    var action: (() -> Void)?

    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        iconColor: Color = .brand,
        actionTitle: String = "See All",
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let systemImage = systemImage {
                        Image(systemName: systemImage)
                            .foregroundStyle(iconColor)
                    }
                    Text(title)
                        .font(.sectionTitle)
                        .foregroundStyle(Color.textPrimary)
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
            if let action = action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brand)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Initials on a brand-blue circle.
struct AvatarView: View {
    let initials: String
    var size: CGFloat = 56

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [Color.brand, Color.brand.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Circle()
            )
            .accessibilityHidden(true)
    }
}

/// "Ends in 02:14:09", ticking every second.
struct CountdownTimer: View {
    let endDate: Date
    var tint: Color = .deal

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text("Ends in")
                Text(Formatters.countdown(endDate.timeIntervalSince(context.date)))
                    .monospacedDigit()
                    .fontWeight(.bold)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: Capsule())
        }
    }
}

// MARK: - States

/// An icon, a title, a message and an optional action — for empty lists and dead ends.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    init(systemImage: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Color.brand)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 104, height: 104)
                .background(Color.brand.opacity(0.1), in: Circle())

            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, isFullWidth: false, action: action)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

/// What went wrong, and a way to try again.
struct ErrorStateView: View {
    var title: String = "Something went wrong"
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 42))
                .foregroundStyle(Color.danger)
                .frame(width: 100, height: 100)
                .background(Color.danger.opacity(0.1), in: Circle())

            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.title3.weight(.bold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton("Try Again", systemImage: "arrow.clockwise", style: .outlined, isFullWidth: false, action: retry)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

/// A two-column grid of card skeletons, for any product grid that is loading.
struct ProductGridSkeleton: View {
    var count: Int = 6

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.sm), GridItem(.flexible(), spacing: Theme.Spacing.sm)], spacing: Theme.Spacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                ProductCardSkeleton()
            }
        }
    }
}

// MARK: - Orders

extension OrderStatus {
    var tint: Color {
        switch self {
        case .placed, .confirmed: return .brand
        case .packed, .shipped, .outForDelivery: return .deal
        case .delivered: return .success
        case .cancelled: return .danger
        }
    }
}

/// The order's status as a coloured pill.
struct OrderStatusBadge: View {
    let status: OrderStatus

    var body: some View {
        Label(status.title, systemImage: status.symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 4)
            .background(status.tint.opacity(0.12), in: Capsule())
    }
}

/// The order's journey as a vertical timeline: Order Placed → Confirmed → Packed → Shipped →
/// Out for Delivery → Delivered, with the time each stage was reached.
struct OrderStatusView: View {
    let order: Order

    private var stages: [OrderStatus] {
        order.status == .cancelled ? [.placed, .cancelled] : OrderStatus.trackingStages
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(stages.enumerated()), id: \.element) { index, stage in
                row(for: stage, isLast: index == stages.count - 1)
            }
        }
    }

    private func row(for stage: OrderStatus, isLast: Bool) -> some View {
        let event = order.event(for: stage)
        let isReached = event != nil
        let isCurrent = stage == order.status
        let nextReached = stages.firstIndex(of: stage).map { $0 + 1 < stages.count && order.event(for: stages[$0 + 1]) != nil } ?? false

        return HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isReached ? stage.tint : Color.surfaceMuted)
                        .frame(width: 28, height: 28)
                    Image(systemName: isReached ? (stage == .cancelled ? "xmark" : "checkmark") : stage.symbolName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isReached ? Color.white : Color.textTertiary)
                }
                .overlay {
                    if isCurrent && order.isActive {
                        Circle()
                            .stroke(stage.tint.opacity(0.35), lineWidth: 6)
                            .frame(width: 38, height: 38)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(nextReached ? stage.tint : Color.divider)
                        .frame(width: 2)
                        .frame(minHeight: 36)
                }
            }
            .frame(width: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(stage.title)
                    .font(.subheadline.weight(isCurrent ? .bold : .semibold))
                    .foregroundStyle(isReached ? Color.textPrimary : Color.textSecondary)
                if let event = event {
                    Text(Formatters.dateTime(event.date))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    if isCurrent {
                        Text(event.note)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                } else if stage == .delivered {
                    Text("Expected by \(Formatters.shortDate(order.estimatedDelivery))")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, isLast ? 0 : Theme.Spacing.md)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Six dots along a line, filled to the current stage — the compact form of `OrderStatusView` for lists.
struct OrderProgressBar: View {
    let order: Order

    var body: some View {
        if order.status == .cancelled {
            OrderStatusBadge(status: .cancelled)
        } else {
            let current = order.status.stageIndex ?? 0
            let stages = OrderStatus.trackingStages
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    ForEach(Array(stages.enumerated()), id: \.element) { index, _ in
                        Circle()
                            .fill(index <= current ? order.status.tint : Color.divider)
                            .frame(width: 9, height: 9)
                        if index < stages.count - 1 {
                            Rectangle()
                                .fill(index < current ? order.status.tint : Color.divider)
                                .frame(height: 2)
                        }
                    }
                }
                Text(order.status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(order.status.tint)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(order.status.title), step \(current + 1) of \(stages.count)")
        }
    }
}

// MARK: - Checkout

/// Numbered steps joined by lines; steps already reached can be tapped to go back to them.
struct StepIndicator: View {
    let steps: [String]
    let currentIndex: Int
    /// The furthest step reached; steps up to it are tappable.
    var reachedIndex: Int?
    var onSelect: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, title in
                Button {
                    onSelect?(index)
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(index <= currentIndex ? Color.brand : Color.surfaceMuted)
                                .frame(width: 26, height: 26)
                            if index < currentIndex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(index == currentIndex ? Color.white : Color.textSecondary)
                            }
                        }
                        Text(title)
                            .font(.caption2.weight(index == currentIndex ? .bold : .medium))
                            .foregroundStyle(index <= currentIndex ? Color.textPrimary : Color.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(minWidth: 56)
                }
                .buttonStyle(.plain)
                .disabled(onSelect == nil || index > (reachedIndex ?? currentIndex) || index == currentIndex)

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentIndex ? Color.brand : Color.divider)
                        .frame(height: 2)
                        .padding(.bottom, 18)
                }
            }
        }
        .animation(Theme.spring, value: currentIndex)
    }
}

/// The price breakdown card: MRP, discounts, delivery, tax and the total, with the savings called out.
struct PriceSummaryView: View {
    let breakdown: PriceBreakdown
    var couponCode: String?
    var title: String = "Price Details"

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.textSecondary)

            row("Price (\(breakdown.itemCount) item\(breakdown.itemCount == 1 ? "" : "s"))", Formatters.currency(breakdown.originalTotal))
            if breakdown.productDiscount > 0 {
                row("Discount", "−\(Formatters.currency(breakdown.productDiscount))", color: .success)
            }
            if breakdown.couponDiscount > 0 {
                row(couponTitle, "−\(Formatters.currency(breakdown.couponDiscount))", color: .success)
            }
            row("Delivery Charges", breakdown.deliveryFee == 0 ? "FREE" : Formatters.currency(breakdown.deliveryFee), color: breakdown.deliveryFee == 0 ? .success : .textPrimary)
            row("Tax (GST \(Int(PriceBreakdown.taxRate * 100))%)", Formatters.currency(breakdown.tax))

            Divider()

            HStack {
                Text("Total Amount")
                    .font(.headline)
                Spacer()
                Text(Formatters.currency(breakdown.total))
                    .font(.priceMedium)
                    .contentTransition(.numericText())
            }

            if breakdown.totalSavings > 0 {
                Label("You will save \(Formatters.currency(breakdown.totalSavings)) on this order", systemImage: "tag.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.success)
                    .padding(Theme.Spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.success.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.Radius.xs, style: .continuous))
            }
        }
        .cardStyle()
        .animation(Theme.spring, value: breakdown)
    }

    private var couponTitle: String {
        guard let couponCode = couponCode else {
            return "Coupon"
        }
        return "Coupon (\(couponCode))"
    }

    private func row(_ title: String, _ value: String, color: Color = .textPrimary) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .font(.subheadline)
    }
}
