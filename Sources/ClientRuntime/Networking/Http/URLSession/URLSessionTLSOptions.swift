//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct URLSessionTLSOptions: TLSConfiguration {

    /// Filename of the turst certificate file in main bundle (.cer)
    public var certificate: String?

    /// Not supported for URLSession HTTP Client
    public var certificateDir: String?

    /// Not supported for URLSession HTTP Client
    public var privateKey: String?

    /// Optional path to PKCS #12 certificate , in PEM format
    public var pkcs12Path: String?

    /// Optional PKCS#12 password
    public var pkcs12Password: String?

    /// Information is provided to use custom trust store
    public var useSelfSignedCertificate: Bool {
        return certificate != nil
    }

    /// Information is provided to use custom key store
    public var useProvidedKeystore: Bool {
        return pkcs12Path != nil && pkcs12Password != nil
    }

    public init(
        certificate: String? = nil, // .cer
        pkcs12Path: String? = nil, // .p12
        pkcs12Password: String? = nil
    ) {
        self.certificate = certificate
        self.pkcs12Path = pkcs12Path
        self.pkcs12Password = pkcs12Password
    }
}
