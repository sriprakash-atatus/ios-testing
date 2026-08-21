/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - renamed `dd*` types to `Atatus*`; renamed the `DD` symbol prefix to
// `AT`; rebranded the licence header.

import Foundation

/// Establishes a communications channel from UITests runner to the app under tests (allows sending messages
/// from `AtatusIntegrationTests` to `Example` app).
///
/// Ref.: https://developer.apple.com/documentation/corefoundation/cfmessageport-rs2
///
/// Note: this class is used by two targets: `AtatusIntegrationTests` (sender) and `Example` (receiver).
internal class MessagePortChannel {
    private static let portName = "ATExampleAppPort" as CFString

    enum Message: Int32 {
        case endRUMSession = 0x1111
    }

    struct ChannelError: Error, CustomStringConvertible {
        let description: String
    }

    static func createSender() throws -> Sender {
        return try Sender()
    }

    static func createReceiver() throws -> Receiver {
        return try Receiver()
    }

    // MARK: - Sending messages

    /// Sender, obtained in `UITests` runner process. Sends messages to `MessagePortChannel.portName`.
    internal class Sender {
        private let remotePort: CFMessagePort

        /// - Parameter timeout: how long to keep waiting for the app to register its port.
        fileprivate init(timeout: TimeInterval = 10) throws {
            // ATCHG: `CFMessagePortCreateRemote` returns nil while the app process has not yet
            // registered its local port. The app registers it in `UITestsAppConfiguration.init()`,
            // which races the runner reaching this call — failing on the first miss made every
            // scenario that ends a RUM session intermittently fail with "failed to instantiate
            // remote port". Polling turns that race into a wait.
            let deadline = Date().addingTimeInterval(timeout)
            var port = CFMessagePortCreateRemote(nil, MessagePortChannel.portName)
            while port == nil && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.1)
                port = CFMessagePortCreateRemote(nil, MessagePortChannel.portName)
            }

            guard let remotePort = port else {
                throw ChannelError(
                    description: """
                    ⚠️ `MessagePortChannel.Sender` - failed to instantiate remote port after \(timeout)s. \
                    The app either is not running or never reached `UITestsAppConfiguration.init()`.
                    """
                )
            }
            // ATCHG: End
            self.remotePort = remotePort
        }

        func send(message: Message) throws {
            let timeout: CFTimeInterval = 5.0
            let replyMode = CFRunLoopMode.defaultMode.rawValue // use `default` mode to avaid delivery confirmation
            let deliveryStatus = CFMessagePortSendRequest(remotePort, message.rawValue, nil, timeout, timeout, replyMode, nil)
            if deliveryStatus != kCFMessagePortSuccess {
                throw ChannelError(description: "⚠️ `MessagePortChannel.Sender` - failed to send '\(message)' message")
            }
        }
    }

    // MARK: - Receiving messages

    /// Receiver, obtained in `Example` app process. Receives messages on `MessagePortChannel.portName`.
    internal class Receiver {
        private let localPort: CFMessagePort
        private static var currentListener: ((Message) -> Void)?

        fileprivate init() throws {
            func callback(port: CFMessagePort?, msgid: Int32, data: CFData?, info: UnsafeMutableRawPointer?) -> Unmanaged<CFData>? {
                if let message = Message(rawValue: msgid) {
                    Receiver.currentListener?(message)
                } else {
                    print("⚠️ `MessagePortChannel.Receiver` - failed to read message from `msgid`: \(msgid)")
                }
                return nil
            }

            guard let localPort = CFMessagePortCreateLocal(nil, MessagePortChannel.portName, callback, nil, nil) else {
                throw ChannelError(description: "⚠️ `MessagePortChannel.Receiver` - failed to instantiate local port")
            }
            self.localPort = localPort
        }

        func startListening(_ listener: @escaping (Message) -> Void) {
            precondition(Receiver.currentListener == nil, "Listener was already started")
            Receiver.currentListener = listener
            let runLoopSource = CFMessagePortCreateRunLoopSource(nil, localPort, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.commonModes)
        }
    }
}
