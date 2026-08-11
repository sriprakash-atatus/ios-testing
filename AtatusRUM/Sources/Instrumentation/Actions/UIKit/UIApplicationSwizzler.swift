/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; rebranded the
// licence header.

#if !os(watchOS)
import UIKit
import AtatusInternal

internal final class UIApplicationSwizzler {
    let sendEvent: SendEvent

    init(handler: RUMActionsHandling) throws {
        sendEvent = try SendEvent(handler: handler)
    }

    func swizzle() {
        sendEvent.swizzle()
    }

    internal func unswizzle() {
        sendEvent.unswizzle()
    }

    // MARK: - Swizzlings

    /// Swizzles the `UIApplication.sendEvent(_:)`
    class SendEvent: MethodSwizzler <
        @convention(c) (UIApplication, Selector, UIEvent) -> Bool,
        @convention(block) (UIApplication, UIEvent) -> Bool
    > {
        private static let selector = #selector(UIApplication.sendEvent(_:))
        private let method: Method
        private let handler: RUMActionsHandling

        init(handler: RUMActionsHandling) throws {
            self.method = try dd_class_getInstanceMethod(UIApplication.self, Self.selector)
            self.handler = handler
        }

        func swizzle() {
            typealias Signature = @convention(block) (UIApplication, UIEvent) -> Bool
            swizzle(method) { previousImplementation -> Signature in
                return { [weak handler = self.handler] application, event  in
                    handler?.notify_sendEvent(application: application, event: event)
                    return previousImplementation(application, Self.selector, event)
                }
            }
        }
    }
}
#endif
