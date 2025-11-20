//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/**
 * Configuration settings about TLS set up.
 * All settings are optional.
 * Not specifying them will use the SDK defaults
 */
public protocol TLSConfiguration {

    // Optional path to a PEM certificate
    var certificate: String? { get set }

    // Optional path to certificate directory
    var certificateDir: String? { get set }

    // Optional path to a PEM format private key
    var privateKey: String? { get set }

    // Optional path to PKCS #12 certificate , in PEM format
    var pkcs12Path: String? { get set }

    // Optional PKCS#12 password
    var pkcs12Password: String? { get set }
}
