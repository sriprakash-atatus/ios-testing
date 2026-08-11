/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the `dd` name to `Atatus` in comments and docs; rebranded
// the licence header.

#if canImport(SwiftUI)
import SwiftUI
import AtatusInternal

/// `SwiftUI.ViewModifier` which notifes RUM instrumentation when modified view appears and disappears.
/// It makes an entry point to RUM views instrumentation in SwiftUI.
@available(iOS 13, tvOS 13, watchOS 7, *)
internal struct RUMViewModifier: SwiftUI.ViewModifier {
    /// Atatus RUM instrumentation instance
    let instrumentation: RUMInstrumentation?

    /// The Content View identifier.
    /// The id will be unique per modified view.
    let identity: String = UUID().uuidString

    /// View Name used for RUM Explorer.
    let name: String

    /// View Path used for RUM Explorer.
    let path: String

    /// Custom attributes to attach to the View.
    let attributes: [AttributeKey: AttributeValue]

    func body(content: Content) -> some View {
        content.onAppear {
            instrumentation?.viewsHandler
                .notify_onAppear(
                    identity: identity,
                    name: name,
                    path: path,
                    attributes: attributes
                )
        }
        .onDisappear {
            instrumentation?.viewsHandler
                .notify_onDisappear(identity: identity)
        }
    }
}

@available(iOS 13, tvOS 13, watchOS 7, *)
public extension SwiftUI.View {
    /// Monitor this view with Atatus RUM. A start and stop events will be logged when this view appears
    /// and disappears.
    ///
    /// - Parameters:
    ///   - name: the View name used for RUM Explorer.
    ///   - attributes: custom attributes to attach to the View.
    ///   - core: The SDK core instance.
    /// - Returns: This view after applying a `ViewModifier` for monitoring the view.
    func trackRUMView(
        name: String,
        attributes: [AttributeKey: AttributeValue] = [:],
        in core: AtatusCoreProtocol = CoreRegistry.default
    ) -> some View {
        let path = "\(name)/\(typeDescription.hashValue)"
        let instrumentation = core.get(feature: RUMFeature.self)?.instrumentation
        return modifier(
            RUMViewModifier(
                instrumentation: instrumentation,
                name: name,
                path: path,
                attributes: attributes
            )
        )
    }
}

#endif
