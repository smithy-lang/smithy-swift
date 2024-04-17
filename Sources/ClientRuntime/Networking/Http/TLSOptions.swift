//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct TLSOptions {

    /// Custom TLS configuration for HTTPS connections with CRT client.
    ///
    /// Enables specifying client certificates and trust stores for secure communication.
    /// Defaults to system's TLS settings if `nil`.
    public var crtTLSOptions: CRTClientTLSOptions?

    /// Custom TLS configuration for HTTPS connections with URLSession client.
    ///
    /// Enables specifying client certificates and trust stores for secure communication.
    /// Defaults to system's TLS settings if `nil`.
    public var urlSessionTLSOptions: URLSessionTLSOptions?

    /// On apple devices using URLSession http client set urlSessionTLSOptions
    /// On linux devices using CRT http client set tlsOptions
    public init(
        crtTLSOptions: CRTClientTLSOptions? = nil,
        urlSessionTLSOptions: URLSessionTLSOptions? = nil
    ) {
        // Default to nil
        self.crtTLSOptions = crtTLSOptions

        // Set URLSession client tls options
        self.urlSessionTLSOptions = urlSessionTLSOptions
    }
}
