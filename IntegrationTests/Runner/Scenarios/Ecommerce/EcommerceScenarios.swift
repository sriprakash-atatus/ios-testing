/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: An e-commerce app built on the agent, used by `.github/workflows/ios-agent-test.yml`.
//
// FlipShop, a marketplace laid out the way Indian shopping apps are: a home feed with search,
// categories, offer banners and deals; search with autocomplete; sortable listings; product pages
// with offers, a pincode delivery check and a wishlist; a cart with quantity steppers and a price
// breakdown off the MRP; a delivery address step; UPI / card / net banking / cash on delivery
// payment; and an order confirmation with a tracking timeline. Prices are in rupees.
//
// The other scenarios call the SDK's manual APIs. This one calls none of them: the store's own code
// (`Scenarios/Ecommerce/Store`) has no SDK imports at all beyond the instrumented `URLSession` it
// creates. Everything that reaches the intake is captured by the agent on its own —
//
//   · RUM views      from the view controllers appearing as the shop walks its funnel
//   · RUM actions    from real taps, through `uiKitActionsPredicate`
//   · RUM resources  from the store's real requests to its backend
//   · Network spans  from the same requests, with trace headers propagated to the backend
//   · Mobile vitals  CPU, memory and refresh rate, sampled while the shop runs
//   · App hangs and frustration signals
//   · Session Replay a recording of the screens
//
// — which makes this the scenario that answers "does the agent report a real app correctly?", as
// opposed to "does each SDK method work?".
//
// Note on Logs: the Logs product has no auto-capture — every log is written by application code, so
// a scenario that reports nothing by hand produces no logs. Logs is still enabled here, so the
// feature is initialized the way a real app would have it, but this scenario is not expected to
// upload log payloads. `AtatusDemoScenario` remains the one that exercises the Logs API.
//
// The funnel walks itself (see `ECAutoPilot`), so `simctl launch` alone drives it without a test
// runner. `customEndpoint` is read from the server mock configuration where there is one, so this
// runs against the local mock intake as well as against a real Atatus intake, where every feature
// falls back to `AtatusSite.serverUrl`.

import UIKit
import AtatusCore
import AtatusLogs
import AtatusRUM
import AtatusTrace
import AtatusSessionReplay

struct EcommerceUIKitRUMViewsPredicate: UIKitRUMViewsPredicate {
    func rumView(for viewController: UIViewController) -> RUMView? {
        var view: RUMView?
        switch viewController {
        case is ECHomeViewController:
            view = RUMView(name: "Home")
            view?.path = "ECHomeViewController"
        case is ECSearchViewController:
            view = RUMView(name: "Search")
            view?.path = "ECSearchViewController"
        case is ECProductListViewController:
            view = RUMView(name: "Product Listing")
            view?.path = "ECProductListViewController"
        case is ECProductDetailViewController:
            view = RUMView(name: "Product Details")
            view?.path = "ECProductDetailViewController"
        case is ECWishlistViewController:
            view = RUMView(name: "Wishlist")
            view?.path = "ECWishlistViewController"
        case is ECCartViewController:
            view = RUMView(name: "Cart")
            view?.path = "ECCartViewController"
        case is ECAddressViewController:
            view = RUMView(name: "Delivery Address")
            view?.path = "ECAddressViewController"
        case is ECCheckoutViewController:
            view = RUMView(name: "Payment")
            view?.path = "ECCheckoutViewController"
        case is ECOrderConfirmationViewController:
            view = RUMView(name: "Order Confirmation")
            view?.path = "ECOrderConfirmationViewController"
        default:
            return DefaultUIKitRUMViewsPredicate().rumView(for: viewController)
        }
        return view
    }
}

final class AtatusEcommerceScenario: TestScenario {
    static let storyboardName = "AtatusEcommerceScenario"

    func override(configuration: inout Atatus.Configuration) {
        configuration.version = "2.0.0"
    }

    func configureFeatures() {
        // The store's backend. Declaring it first party is what gets trace headers onto the shop's
        // requests; resource tracking itself applies to every request the instrumented session makes.
        let firstPartyHosts: Set<String> = ECStoreAPI.host.isEmpty ? [] : [ECStoreAPI.host]

        var rum = RUM.Configuration(applicationID: Environment.rumApplicationID())
        rum.uiKitViewsPredicate = EcommerceUIKitRUMViewsPredicate()
        rum.uiKitActionsPredicate = DefaultUIKitRUMActionsPredicate()
        var urlSessionTracking = RUM.Configuration.URLSessionTracking()
        if !firstPartyHosts.isEmpty {
            urlSessionTracking.firstPartyHostsTracing = .trace(hosts: firstPartyHosts, sampleRate: 100)
        }
        rum.urlSessionTracking = urlSessionTracking
        rum.trackFrustrations = true
        rum.trackBackgroundEvents = true
        rum.appHangThreshold = 0.25
        rum.vitalsUpdateFrequency = .frequent
        rum.telemetrySampleRate = 0
        rum.customEndpoint = Environment.serverMockConfiguration()?.rumEndpoint
        rum.resourceEventMapper = { resourceEvent in
            if resourceEvent.resource.url.contains("heart-beat") || resourceEvent.resource.url.contains("agent-heartbeat") {
                return nil
            }
            return resourceEvent
        }
        RUM.enable(with: rum)

        // Enabled so the feature is initialized as a real app would have it. This scenario writes no
        // logs of its own — see the note at the top of this file.
        Logs.enable(
            with: Logs.Configuration(
                customEndpoint: Environment.serverMockConfiguration()?.logsEndpoint
            )
        )

        var trace = Trace.Configuration(sampleRate: 100)
        trace.networkInfoEnabled = true
        if !firstPartyHosts.isEmpty {
            trace.urlSessionTracking = Trace.Configuration.URLSessionTracking(
                firstPartyHostsTracing: .trace(hosts: firstPartyHosts, sampleRate: 100)
            )
        }
        trace.customEndpoint = Environment.serverMockConfiguration()?.tracesEndpoint
        Trace.enable(with: trace)

        // Enabled after RUM, which the recording rides on. Masking is dialled down to the least the
        // SDK allows, so the funnel is actually readable in a replay viewer.
        var replay = SessionReplay.Configuration(replaySampleRate: 100)
        replay.textAndInputPrivacyLevel = .maskSensitiveInputs
        replay.imagePrivacyLevel = .maskNone
        replay.touchPrivacyLevel = .show
        replay.customEndpoint = Environment.serverMockConfiguration()?.srEndpoint
        SessionReplay.enable(with: replay)
    }
}
