//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
    public let useSelfSignedCertificate: Bool

    /// Information is provided to use custom key store
    public let useProvidedKeystore: Bool

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

        self.useSelfSignedCertificate = certificatePath != nil && certificateFilename != nil
        self.useProvidedKeystore = keyStoreFilepath != nil && keyStorePassword != nil
    }
}
