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
    public var crtTLSContext: TLSContext? = nil

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
        // Set CRT client tls options with .client mode
        if let _crtTLSOptions = crtTLSOptions {
            do {
                let tlsOptions: TLSContextOptions
                if _crtTLSOptions.useProvidedKeystore == true,
                   let keyStoreFilepath = _crtTLSOptions.keyStoreFilepath,
                   let keyStorePassword = _crtTLSOptions.keyStorePassword {
                    tlsOptions = try .makeMtlsPkcs12FromPath(
                        path: keyStoreFilepath,
                        password: keyStorePassword
                    )
                } else {
                    tlsOptions = TLSContextOptions.makeDefault()
                }

                if _crtTLSOptions.useSelfSignedCertificate == true,
                   let certificatePath = _crtTLSOptions.certificatePath,
                   let certificateFilename = _crtTLSOptions.certificateFilename {
                    try tlsOptions.overrideDefaultTrustStore(
                        caPath: certificatePath,
                        caFile: certificateFilename
                    )
                }

                self.crtTLSContext = try TLSContext(options: tlsOptions, mode: .client)
            } catch {
                let logger = SwiftLogger(label: "HTTPClientConfiguration")
                logger.error(
                    "TLS Options provided are invliad! Could not create TLSContext. " +
                    "Using default options."
                )
            }
        }

        // Set URLSession client tls options
        self.urlSessionTLSOptions = urlSessionTLSOptions
    }
}
