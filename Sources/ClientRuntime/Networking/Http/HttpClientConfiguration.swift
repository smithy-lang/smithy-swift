//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

public class HttpClientConfiguration {

    /// The timeout for establishing a connection, in seconds.
    ///
    /// If none is provided, the client will use default values based on the platform.
    public var connectTimeout: TimeInterval?

    /// The timeout for socket, in seconds.
    /// Sets maximum time to wait between two data packets.
    /// Used to close stale connections that have no activity.
    ///
    /// If no value is provided, the defaut client won't have a socket timeout.
    public var socketTimeout: TimeInterval?

    /// HTTP headers to be submitted with every HTTP request.
    ///
    /// If none is provided, defaults to no extra headers.
    public var defaultHeaders: Headers

    // add any other properties here you want to give the service operations
    // control over to be mapped to the Http Client

    /// The URL scheme to be used for HTTP requests.  Supported values are `http` and `https`.
    ///
    /// If none is provided, the default protocol for the operation will be used
    public var protocolType: ProtocolType?

    /// Creates a configuration object for a SDK HTTP client.
    ///
    /// Not all configuration settings may be followed by all clients.
    /// - Parameters:
    ///   - connectTimeout: The maximum time to wait for a connection to be established.
    ///   - socketTimeout: The maximum time to wait between data packets.
    ///   - defaultHeaders: HTTP headers to be included with every HTTP request.
    ///   Note that certain headers may cause your API request to fail.  Defaults to no headers.
    ///   - protocolType: The HTTP scheme (`http` or `https`) to be used for API requests.  Defaults to the operation's standard configuration.
    public init(
        connectTimeout: TimeInterval? = nil,
        socketTimeout: TimeInterval? = nil,
        protocolType: ProtocolType = .https,
        defaultHeaders: Headers = Headers()
    ) {
        self.socketTimeout = socketTimeout
        self.protocolType = protocolType
        self.defaultHeaders = defaultHeaders
        self.connectTimeout = connectTimeout
    }
}
