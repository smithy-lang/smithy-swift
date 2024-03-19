//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(watchOS) || os(tvOS) || os(visionOS)

public struct URLSessionTLSOptions {
    /// Path to the folder containing the trust store certificate file.
    public var trustStorePath: String?

    /// Filename of the trust store certificate file.
    public var trustStoreFile: String?

    /// Path to the key store (client certificate) file.
    public var keyStorePath: String?

    /// Password for the key store if required.
    public var keyStorePassword: String?

    /// Information is provided to use custom trust store
    public var useCustomTrustStore: Bool

    /// Information is provided to use custom key store
    public var useClientCertificate: Bool

    public init(
        trustStorePath: String? = nil,
        trustStoreFile: String? = nil,
        keyStorePath: String? = nil,
        keyStorePassword: String? = nil
    ) {
        self.trustStorePath = trustStorePath
        self.trustStoreFile = trustStoreFile
        self.keyStorePath = keyStorePath
        self.keyStorePassword = keyStorePassword

        self.useCustomTrustStore = trustStoreFile != nil && trustStorePath != nil
        self.useClientCertificate = keyStorePath != nil && keyStorePassword != nil
    }
}

#endif
