//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import NIOSSL

extension NIOHTTPClientTLSOptions {

    func makeNIOSSLConfiguration() throws -> NIOSSL.TLSConfiguration {
        var tlsConfig = NIOSSL.TLSConfiguration.makeClientConfiguration()

        if useSelfSignedCertificate {
            if let certificateDir = certificateDir, let certificate = certificate {
                let certificatePath = "\(certificateDir)/\(certificate)"
                let certificates = try NIOHTTPClientTLSOptions.loadCertificates(from: certificatePath)
                tlsConfig.trustRoots = .certificates(certificates)
            } else if let certificate = certificate {
                let certificates = try NIOHTTPClientTLSOptions.loadCertificates(from: certificate)
                tlsConfig.trustRoots = .certificates(certificates)
            }
        }

        if useProvidedKeystore {
            if let pkcs12Path = pkcs12Path, let pkcs12Password = pkcs12Password {
                let bundle = try NIOHTTPClientTLSOptions.loadPKCS12Bundle(from: pkcs12Path, password: pkcs12Password)
                tlsConfig.certificateChain = bundle.certificateChain.map { .certificate($0) }
                tlsConfig.privateKey = .privateKey(bundle.privateKey)
            } else if let certificate = certificate, let privateKey = privateKey {
                let cert = try NIOHTTPClientTLSOptions.loadCertificate(from: certificate)
                let key = try NIOHTTPClientTLSOptions.loadPrivateKey(from: privateKey)
                tlsConfig.certificateChain = [.certificate(cert)]
                tlsConfig.privateKey = .privateKey(key)
            }
        }

        return tlsConfig
    }
}

extension NIOHTTPClientTLSOptions {

    static func loadCertificates(from filePath: String) throws -> [NIOSSLCertificate] {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return try NIOSSLCertificate.fromPEMBytes(Array(fileData))
    }

    static func loadCertificate(from filePath: String) throws -> NIOSSLCertificate {
        let certificates = try loadCertificates(from: filePath)
        guard let certificate = certificates.first else {
            throw NIOHTTPClientTLSError.noCertificateFound(filePath)
        }
        return certificate
    }

    static func loadPrivateKey(from filePath: String) throws -> NIOSSLPrivateKey {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        return try NIOSSLPrivateKey(bytes: Array(fileData), format: .pem)
    }

    static func loadPKCS12Bundle(from filePath: String, password: String) throws -> NIOSSLPKCS12Bundle {
        do {
            return try NIOSSLPKCS12Bundle(file: filePath, passphrase: password.utf8)
        } catch {
            throw NIOHTTPClientTLSError.invalidPKCS12(filePath, underlying: error)
        }
    }
}

public enum NIOHTTPClientTLSError: Error, LocalizedError {
    case noCertificateFound(String)
    case invalidPKCS12(String, underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .noCertificateFound(let path):
            return "No certificate found at path: \(path)"
        case .invalidPKCS12(let path, let underlying):
            return "Failed to load PKCS#12 file at path: \(path). Error: \(underlying.localizedDescription)"
        }
    }
}
