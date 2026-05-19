//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.URIScheme

/// Configuration for routing HTTP requests through an HTTP proxy.
public struct Proxy: Sendable, Equatable {

    /// The proxy host.
    public let host: String

    /// The proxy port.
    public let port: Int

    /// The scheme used to connect to the proxy itself. Defaults to `.http`.
    public let scheme: URIScheme

    /// Optional username for proxy authentication.
    public let username: String?

    /// Optional password for proxy authentication.
    public let password: String?

    public init(
        host: String,
        port: Int,
        scheme: URIScheme = .http,
        username: String? = nil,
        password: String? = nil
    ) {
        self.host = host
        self.port = port
        self.scheme = scheme
        self.username = username
        self.password = password
    }
}
