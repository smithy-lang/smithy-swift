//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct CRTClientTLSOptions: TLSConfiguration {

    /// Optional PEM certificate filename
    public var certificate: String?

    /// Optional path to certificate directory
    public var certificateDir: String?

    /// Optional path to a PEM format private key
    public var privateKey: String?

    /// Optional path to PKCS #12 certificate , in PEM format
    public var pkcs12Path: String?

    /// Optional PKCS#12 password
    public var pkcs12Password: String?

    /// Information is provided to use custom trust store
    public var useSelfSignedCertificate: Bool {
        return certificateDir != nil && certificate != nil
    }

    /// Information is provided to use custom key store
    public var useProvidedKeystore: Bool {
        return (pkcs12Path != nil && pkcs12Password != nil) ||
            (privateKey != nil && useSelfSignedCertificate)
    }

    public init(
        certificateDir: String? = nil,
        certificate: String? = nil, // .cer
        pkcs12Path: String? = nil, // .p12 PEM
        pkcs12Password: String? = nil,
        privateKey: String? = nil
    ) {
        self.certificateDir = certificateDir
        self.certificate = certificate
        self.pkcs12Path = pkcs12Path
        self.pkcs12Password = pkcs12Password
        self.privateKey = privateKey
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
                #if os(tvOS) || os(iOS) || os(watchOS) || os(macOS) // visionOS not supported
                if let path = pkcs12Path, let password = pkcs12Password {
                    tlsOptions = try .makeMTLS(pkcs12Path: path, password: password)
                }
                #endif
            } else if self.useSelfSignedCertificate {
                #if os(Linux) || os(macOS)
                if let certPath = certificateDir,
                    let certFilename = certificate,
                    let privateKeyPath = pkcs12Path {
                    let certFilepath = "\(certPath)/\(certFilename)"
                    tlsOptions = try .makeMTLS(certificatePath: certFilepath, privateKeyPath: privateKeyPath)
                }
                #endif
            }

            if self.useSelfSignedCertificate, let certPath = certificateDir, let certFilename = certificate {
                try tlsOptions.overrideDefaultTrustStore(caPath: certPath, caFile: certFilename)
            }

            tlsContext = try TLSContext(options: tlsOptions, mode: .client)
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
