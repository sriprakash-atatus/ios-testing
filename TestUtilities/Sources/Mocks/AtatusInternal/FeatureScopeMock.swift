/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed module imports `ddInternal` -> `AtatusInternal`; renamed
// `dd*` types to `Atatus*`; rebranded the licence header.

import Foundation
import AtatusInternal

public final class FeatureScopeMock: FeatureScope, @unchecked Sendable {
    private struct DeferredEventWriteContext {
        let bypassConsent: Bool
        let block: (AtatusContext, Writer) -> Void
    }

    private struct EventWriterMock: Writer {
        weak var scope: FeatureScopeMock?
        let bypassConsent: Bool

        func write<T, M>(value: T, metadata: M?, completion: @escaping CompletionHandler) where T: Encodable, M: Encodable {
            scope?.events.append((value, metadata, bypassConsent))
            completion()
        }
    }

    @ReadWriteLock
    public var contextMock: AtatusContext
    @ReadWriteLock
    private var events: [(event: Encodable, metadata: Encodable?, bypassConsent: Bool)] = []
    @ReadWriteLock
    private var messages: [FeatureMessage] = []
    @ReadWriteLock
    private var deferredEventWriteContexts: [DeferredEventWriteContext] = []
    private let shouldDeferEventWriteContext: Bool
    public let dataStore: DataStore

    public init(
        context: AtatusContext = .mockAny(),
        dataStore: DataStore = DataStoreMock(),
        deferEventWriteContext: Bool = false
    ) {
        self.contextMock = context
        self.dataStore = dataStore
        self.shouldDeferEventWriteContext = deferEventWriteContext
    }

    public func eventWriteContext(bypassConsent: Bool, _ block: @escaping (AtatusContext, Writer) -> Void) {
        guard shouldDeferEventWriteContext else {
            block(contextMock, EventWriterMock(scope: self, bypassConsent: bypassConsent))
            return
        }

        deferredEventWriteContexts.append(.init(bypassConsent: bypassConsent, block: block))
    }

    public func flushDeferredEventWriteContexts() {
        let deferredEventWriteContexts = self.deferredEventWriteContexts
        self.deferredEventWriteContexts.removeAll()

        deferredEventWriteContexts.forEach {
            $0.block(contextMock, EventWriterMock(scope: self, bypassConsent: $0.bypassConsent))
        }
    }

    public func context(_ block: @escaping (AtatusContext) -> Void) {
        block(contextMock)
    }

    public var telemetry: Telemetry { telemetryMock }

    public func send(message: FeatureMessage, else fallback: @escaping () -> Void) {
        messages.append(message)
    }
    public func set<Context>(context: @escaping () -> Context?) where Context: AdditionalContext {
        contextMock.set(additionalContext: context())
    }

    public func set(anonymousId: String?) {
        self.anonymousId = anonymousId
    }

    // MARK: - Side Effects Observation

    /// Retrieve anonymous events written through Even Write Context API.
    public var eventsWritten: [Encodable] { events.map { $0.event } }

    /// Retrieve typed events written through Even Write Context API.
    public func eventsWritten<T>(ofType type: T.Type = T.self) -> [T] where T: Encodable {
        return events.compactMap { $0.event as? T }
    }

    // swiftlint:disable function_default_parameter_at_end
    /// Retrieve typed events written through Even Write Context API with given `bypassConsent` flag.
    public func eventsWritten<T>(
        ofType type: T.Type = T.self,
        withBypassConsent bypassConsent: Bool
    ) -> [T] where T: Encodable {
        return events.filter { $0.bypassConsent == bypassConsent }.compactMap { $0.event as? T }
    }
    // swiftlint:enable function_default_parameter_at_end

    /// Retrieve data written in Data Store.
    public var dataStoreMock: DataStoreMock {
        guard let dataStoreMock = dataStore as? DataStoreMock else {
            preconditionFailure("FeatureScopeMock initialized with a non-DataStoreMock store")
        }
        return dataStoreMock
    }

    /// Retrieve telemetries sent to Telemetry endpoint.
    public let telemetryMock = TelemetryMock()

    /// Retrieve messages sent over Message Bus.
    public func messagesSent() -> [FeatureMessage] {
        return messages
    }

    /// Retrieve last set anonymous ID.
    public private(set) var anonymousId: String?
}
