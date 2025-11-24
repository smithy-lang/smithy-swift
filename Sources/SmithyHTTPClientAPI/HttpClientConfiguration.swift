//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import struct Foundation.TimeInterval
import enum Smithy.URIScheme
import struct SmithyHTTPAPI.Headers

public class HTTPClientConfiguration {

    /// The timeout for establishing a connection, in seconds.
    ///
    /// If none is provided, the client will use default values based on the platform.
    public var connectTimeout: TimeInterval?

    /// The timeout for socket, in seconds.
    /// Sets maximum time to wait between two data packets.
    /// Used to close stale connections that have no activity.
    ///
    /// Defaults to 60 seconds if no value is provided.
    public var socketTimeout: TimeInterval

    /// HTTP headers to be submitted with every HTTP request.
    ///
    /// If none is provided, defaults to no extra headers.
    public var defaultHeaders: Headers

    /// The maximum connections the HTTP client makes per host or per endpoint depending on the OS.
    ///
    /// For Apple platforms, it will be per host.
    /// For Linux, it will be per endpoint (protocol + host + port).
    public var maxConnections: Int

    // add any other properties here you want to give the service operations
    // control over to be mapped to the Http Client

    /// The URL scheme to be used for HTTP requests.  Supported values are `http` and `https`.
    ///
    /// If none is provided, the default protocol for the operation will be used
    public var protocolType: URIScheme?

    /// Custom TLS configuration for HTTPS connections.
    ///
    /// Enables specifying client certificates and trust stores for secure communication.
    /// Defaults to system's TLS settings if `nil`.
    public var tlsConfiguration: (any TLSConfiguration)?

    /// HTTP Client Telemetry
    public var telemetry: HttpTelemetry?

    /// Creates a configuration object for a SDK HTTP client.
    ///
    /// Not all configuration settings may be followed by all clients.
    /// - Parameters:
    ///   - connectTimeout: The maximum time to wait for a connection to be established.
    ///   - socketTimeout: The maximum time to wait between data packets.
    ///   - defaultHeaders: HTTP headers to be included with every HTTP request.
    ///   Note that certain headers may cause your API request to fail.  Defaults to no headers.
    ///   - protocolType: The HTTP scheme (`http` or `https`) to be used for API requests.  Defaults to the operation's standard configuration.
    ///   - tlsConfiguration: Optional custom TLS configuration for HTTPS requests. If `nil`, defaults to a standard configuration.
    ///   - maxConnections: The maximum number of connections the HTTP client makes per host (for Apple platforms) or per endpoint (for Linux). For non-mac Apple platforms, defaults to 6. For macOS and Linux, defaults to 50.
    public init(
        connectTimeout: TimeInterval? = nil,
        socketTimeout: TimeInterval = 60.0,
        protocolType: URIScheme = .https,
        defaultHeaders: Headers = Headers(),
        tlsConfiguration: (any TLSConfiguration)? = nil,
        telemetry: HttpTelemetry? = nil,
        maxConnections: Int? = nil
    ) {
        self.socketTimeout = socketTimeout
        self.protocolType = protocolType
        self.defaultHeaders = defaultHeaders
        self.connectTimeout = connectTimeout
        self.tlsConfiguration = tlsConfiguration
        self.telemetry = telemetry
        if let maxConnections {
            self.maxConnections = maxConnections
        } else {
            #if os(macOS) || os(Linux)
            self.maxConnections = 50
            #else // iOS, ipadOS, watchOS, tvOS.
            self.maxConnections = 6 // URLSession default.
            #endif
        }
    }
}
