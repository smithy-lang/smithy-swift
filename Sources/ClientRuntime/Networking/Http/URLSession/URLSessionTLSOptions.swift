//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct URLSessionTLSOptions {

    /// Filename of the trust store certificate file in main bundle (.cer).
    public let certificateFile: String?

    /// Name of key store file (.p12).
    public let keyStoreName: String?

    /// Password for the key store if required.
    public let keyStorePassword: String?

    /// Information is provided to use custom trust store
    public var useSelfSignedCertificate: Bool {
        return certificateFile != nil
    }

    /// Information is provided to use custom key store
    public var useProvidedKeystore: Bool {
        return keyStoreName != nil && keyStorePassword != nil
    }

    public init(
        certificateFile: String? = nil, // .cer
        keyStoreName: String? = nil, // .p12
        keyStorePassword: String? = nil
    ) {
        self.certificateFile = certificateFile
        self.keyStoreName = keyStoreName
        self.keyStorePassword = keyStorePassword
    }
}
