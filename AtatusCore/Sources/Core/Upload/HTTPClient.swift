/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

// ATCHG: Atatus SDK migration - rebranded the licence header.

import Foundation

/// Defines a type responsible for sending HTTP requests.
internal protocol HTTPClient {
    /// Sends the provided request using HTTP.
    /// - Parameters:
    ///   - request: The request to be sent.
    ///   - delegate: The task-specific delegate.
    ///   - completion: A closure that receives a Result containing either an HTTPURLResponse or an Error.
    func send(request: URLRequest, delegate: URLSessionTaskDelegate?, completion: @escaping (Result<HTTPURLResponse, Error>) -> Void)
}

extension HTTPClient {
    /// Sends the provided request using HTTP.
    /// - Parameters:
    ///   - request: The request to be sent.
    ///   - completion: A closure that receives a Result containing either an HTTPURLResponse or an Error.
    func send(request: URLRequest, completion: @escaping (Result<HTTPURLResponse, Error>) -> Void) {
        self.send(request: request, delegate: nil, completion: completion)
    }
}
