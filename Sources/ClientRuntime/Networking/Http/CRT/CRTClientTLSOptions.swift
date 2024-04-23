//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct CRTClientTLSOptions {

    /// Path to the trust store certificate
    public let certificatePath: String?

    /// Filename of the trust store certificate file in main bundle
    public let certificateFilename: String?

    /// Name of key store file. ex. /path/file
    public let keyStoreFilepath: String?

    /// Password for the key store if required.
    public let keyStorePassword: String?

    /// Path to a private key
    public let privateKeyFilepath: String?

    /// Information is provided to use custom trust store
    public var useSelfSignedCertificate: Bool {
        return certificatePath != nil && certificateFilename != nil
    }

    /// Information is provided to use custom key store
    public var useProvidedKeystore: Bool {
        return (keyStoreFilepath != nil && keyStorePassword != nil) ||
            (privateKeyFilepath != nil && useSelfSignedCertificate)
    }

    public init(
        certificatePath: String? = nil,
        certificateFilename: String? = nil, // .cer
        keyStoreFilepath: String? = nil, // .p12 PEM
        keyStorePassword: String? = nil
    ) {
        self.certificatePath = certificatePath
        self.certificateFilename = certificateFilename
        self.keyStoreFilepath = keyStoreFilepath
        self.keyStorePassword = keyStorePassword
    }
}

extension CRTClientTLSOptions {
    func resolveContext() -> TLSContext? {
        // Provide default tls context (nil)
        var tlsContext: TLSContext?

        // Set CRT client tls options with .client mode
        do {
            // Set tlsOptions to default value
            var tlsOptions = TLSContextOptions.makeDefault()

            if self.useProvidedKeystore {
                #if os(tvOS) || os(iOS) || os(watchOS) || os(macOS)
                if let path = keyStoreFilepath, let password = keyStorePassword {
                    tlsOptions = try .makeMTLS(pkcs12Path: path, password: password)
                }
                #else
                if let certPath = certificatePath,
                    let certFilename = certificateFilename,
                    let privateKeyPath = privateKeyFilepath {
                    let certFilepath = "\(certPath)/\(certFilename)"
                    tlsOptions = try .makeMTLS(certificatePath: certFilepath, privateKeyPath: privateKeyPath)
                }
                #endif
            }

            if self.useSelfSignedCertificate, let certPath = certificatePath, let certFilename = certificateFilename {
                try tlsOptions.overrideDefaultTrustStore(caPath: certPath, caFile: certFilename)
            }

            return try TLSContext(options: tlsOptions, mode: .client)
        } catch {
            let logger = SwiftLogger(label: "HTTPClientConfiguration")
            logger.error(
                "TLS Options provided are invliad! Could not create TLSContext. " +
                "Using default options."
            )
        }
        return tlsContext
    }
}
