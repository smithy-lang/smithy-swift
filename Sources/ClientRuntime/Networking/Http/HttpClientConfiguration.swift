//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval
import enum AwsCommonRuntimeKit.LogLevel

public class HttpClientConfiguration {

    /// The timeout for a request, in seconds.
    ///
    /// If none is provided, the client will use default values based on the platform.
    public var connectTimeout: TimeInterval?

    /// HTTP headers to be submitted with every HTTP request.
    ///
    /// If none is provided, defaults to no extra headers.
    public var defaultHeaders: Headers

    /// The log level to use for AWS-provided HTTP client on Linux.
    /// Only effective if no custom HTTP client has been provided.
    ///
    /// If none is provided, defaults to `LogLevel.none` log level.
    public var customLogLevel: LogLevel

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
    ///   - connectTimeout: The maximum time to wait for a response without receiving any data.
    ///   - defaultHeaders: HTTP headers to be included with every HTTP request.
    ///   Note that certain headers may cause your API request to fail.  Defaults to no headers.
    ///   - protocolType: The HTTP scheme (`http` or `https`) to be used for API requests.  Defaults to the operation's standard configuration.
    public init(
        connectTimeout: TimeInterval? = nil,
        protocolType: ProtocolType = .https,
        defaultHeaders: Headers = Headers(),
        customLogLevel: LogLevel = .none
    ) {
        self.protocolType = protocolType
        self.defaultHeaders = defaultHeaders
        self.connectTimeout = connectTimeout
        self.customLogLevel = customLogLevel
    }
}
