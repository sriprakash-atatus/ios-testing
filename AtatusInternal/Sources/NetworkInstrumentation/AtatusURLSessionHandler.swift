/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation

/// An interface for processing `URLSession` task interceptions.
public protocol AtatusURLSessionHandler {
    /// The first party hosts configured for this handler.
    var firstPartyHosts: FirstPartyHosts { get }

    /// Modifies the provided request by injecting trace headers.
    ///
    /// - Parameters:
    ///   - request: The request to be modified.
    ///   - headerTypes: The types of tracing headers to inject into the request.
    ///   - networkContext: The context around the network request
    /// - Returns: A tuple containing the modified request, the injected TraceContext and optional captured state.
    ///            If no trace is injected (e.g., due to sampling), the returned request remains unmodified, and the trace context will be `nil`.
    func modify(request: URLRequest, headerTypes: Set<TracingHeaderType>, networkContext: NetworkContext?) -> (URLRequest, TraceContext?, URLSessionHandlerCapturedState?)

    /// Notifies the handler that the interception has started.
    ///
    /// - Parameters:
    ///   - interception: The URLSession task interception.
    ///   - capturedStates: Captured states optionally provided by the session handler.
    func interceptionDidStart(interception: URLSessionTaskInterception, capturedStates: [any URLSessionHandlerCapturedState])

    /// Notifies the handler that the interception has completed.
    ///
    /// - Parameter interception: The URLSession task interception.
    func interceptionDidComplete(interception: URLSessionTaskInterception)
}

/// Provides a way for session handlers to obtain data during the ``AtatusURLSessionHandler.modify(request:headerTypes:networkContext:)`` call
/// and pass it to ``AtatusURLSessionHandler.interceptionDidStart(interception:capturedStates:)``.
///
/// This is useful when a piece of data needs to be obtained synchronously inside a session handler, and
/// passed to the asynchronous process of setting up the interception that can run on a different thread.
public protocol URLSessionHandlerCapturedState { }

extension AtatusCoreProtocol {
    /// Core extension for registering `URLSession` handlers.
    ///
    /// - Parameter urlSessionHandler: The `URLSession` handler to register.
    public func register(urlSessionHandler: AtatusURLSessionHandler) throws {
        let contextProvider = NetworkContextCoreProvider()
        let feature = get(feature: NetworkInstrumentationFeature.self) ?? .init(networkContextProvider: contextProvider, messageReceiver: contextProvider)
        feature.handlers.append(urlSessionHandler)
        try register(feature: feature)
    }
}

/// Implemented by handlers that support distributed tracing.
public protocol AtatusURLSessionHandlerSupportingDistributedTracing: AtatusURLSessionHandler {
    /// The currently configured distributed tracing sample rate. `nil` if distributed tracing (first part hosts tracing) is not configured.
    var distributedTracingSampleRate: SampleRate? { get }
}
