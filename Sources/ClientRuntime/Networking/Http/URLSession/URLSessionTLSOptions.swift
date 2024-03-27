//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct URLSessionTLSOptions {

    /// Filename of the trust store certificate file in main bundle (.cer).
    public var certificateFile: String?

    /// Name of key store file (.p12).
    public var keyStoreName: String?

    /// Password for the key store if required.
    public var keyStorePassword: String?

    /// Information is provided to use custom trust store
    public var useSelfSignedCertificate: Bool

    /// Information is provided to use custom key store
    public var useProvidedKeystore: Bool

    public init(
        certificateFile: String? = nil,
        keyStoreName: String? = nil,
        keyStorePassword: String? = nil
    ) {
        self.certificateFile = certificateFile
        self.keyStoreName = keyStoreName
        self.keyStorePassword = keyStorePassword

        self.useSelfSignedCertificate = certificateFile != nil
        self.useProvidedKeystore = keyStoreName != nil && keyStorePassword != nil
    }
}
