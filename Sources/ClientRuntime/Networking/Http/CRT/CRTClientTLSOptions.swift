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

    /// Information is provided to use custom trust store
    public var useSelfSignedCertificate: Bool {
        return certificatePath != nil && certificateFilename != nil
    }

    /// Information is provided to use custom key store
    public var useProvidedKeystore: Bool {
        return keyStoreFilepath != nil && keyStorePassword != nil
    }

    public init(
        certificatePath: String? = nil,
        certificateFilename: String? = nil, // .cer
        keyStoreFilepath: String? = nil, // .p12
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
        // Provide default tls context
        var tlsContext: TLSContext?

        // Set CRT client tls options with .client mode
        do {
            let tlsOptions: TLSContextOptions
            if self.useProvidedKeystore == true,
               let keyStoreFilepath = self.keyStoreFilepath,
               let keyStorePassword = self.keyStorePassword {
                tlsOptions = try .makeMtlsPkcs12FromPath(
                    path: keyStoreFilepath,
                    password: keyStorePassword
                )
            } else {
                tlsOptions = TLSContextOptions.makeDefault()
            }

            if self.useSelfSignedCertificate == true,
               let certificatePath = self.certificatePath,
               let certificateFilename = self.certificateFilename {
                try tlsOptions.overrideDefaultTrustStore(
                    caPath: certificatePath,
                    caFile: certificateFilename
                )
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
