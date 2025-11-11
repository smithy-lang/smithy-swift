//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class NIOHTTPClientTLSOptionsTests: XCTestCase {

    func test_init_withDefaults() {
        let tlsOptions = NIOHTTPClientTLSOptions()
        
        XCTAssertNil(tlsOptions.certificate)
        XCTAssertNil(tlsOptions.certificateDir)
        XCTAssertNil(tlsOptions.privateKey)
        XCTAssertNil(tlsOptions.pkcs12Path)
        XCTAssertNil(tlsOptions.pkcs12Password)
        XCTAssertFalse(tlsOptions.useSelfSignedCertificate)
        XCTAssertFalse(tlsOptions.useProvidedKeystore)
    }

    func test_init_withCertificate() {
        let tlsOptions = NIOHTTPClientTLSOptions(certificate: "/path/to/cert.pem")
        
        XCTAssertEqual(tlsOptions.certificate, "/path/to/cert.pem")
        XCTAssertTrue(tlsOptions.useSelfSignedCertificate)
        XCTAssertFalse(tlsOptions.useProvidedKeystore)
    }

    func test_init_withCertificateDir() {
        let tlsOptions = NIOHTTPClientTLSOptions(certificateDir: "/path/to/certs/")
        
        XCTAssertEqual(tlsOptions.certificateDir, "/path/to/certs/")
        XCTAssertTrue(tlsOptions.useSelfSignedCertificate)
        XCTAssertFalse(tlsOptions.useProvidedKeystore)
    }

    func test_init_withPKCS12() {
        let tlsOptions = NIOHTTPClientTLSOptions(
            pkcs12Path: "/path/to/cert.p12",
            pkcs12Password: "password"
        )
        
        XCTAssertEqual(tlsOptions.pkcs12Path, "/path/to/cert.p12")
        XCTAssertEqual(tlsOptions.pkcs12Password, "password")
        XCTAssertFalse(tlsOptions.useSelfSignedCertificate)
        XCTAssertTrue(tlsOptions.useProvidedKeystore)
    }

    func test_init_withCertificateAndPrivateKey() {
        let tlsOptions = NIOHTTPClientTLSOptions(
            certificate: "/path/to/cert.pem",
            privateKey: "/path/to/key.pem"
        )
        
        XCTAssertEqual(tlsOptions.certificate, "/path/to/cert.pem")
        XCTAssertEqual(tlsOptions.privateKey, "/path/to/key.pem")
        XCTAssertTrue(tlsOptions.useSelfSignedCertificate)
        XCTAssertTrue(tlsOptions.useProvidedKeystore)
    }
}
