//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import NIOSSL
import SmithyHTTPClientAPI

public struct SwiftNIOHTTPClientTLSOptions: SmithyHTTPClientAPI.TLSConfiguration, Sendable {

    /// Optional path to a PEM certificate
    public var certificate: String?

    /// Optional path to certificate directory
    public var certificateDir: String?

    /// Optional path to a PEM format private key
    public var privateKey: String?

    /// Optional path to PKCS #12 certificate, in PEM format
    public var pkcs12Path: String?

    /// Optional PKCS#12 password
    public var pkcs12Password: String?

    /// Information is provided to use custom trust store
    public var useSelfSignedCertificate: Bool {
        return certificate != nil || certificateDir != nil
    }

    /// Information is provided to use custom key store
    public var useProvidedKeystore: Bool {
        return (pkcs12Path != nil && pkcs12Password != nil) ||
               (certificate != nil && privateKey != nil)
    }

    public init(
        certificate: String? = nil,
        certificateDir: String? = nil,
        privateKey: String? = nil,
        pkcs12Path: String? = nil,
        pkcs12Password: String? = nil
    ) {
        self.certificate = certificate
        self.certificateDir = certificateDir
        self.privateKey = privateKey
        self.pkcs12Path = pkcs12Path
        self.pkcs12Password = pkcs12Password
    }
}
