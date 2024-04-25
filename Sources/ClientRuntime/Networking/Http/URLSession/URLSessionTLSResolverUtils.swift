//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(watchOS) || os(tvOS) || os(visionOS)

import class Foundation.Bundle
import Security

extension Bundle {
    func certificate(named name: String) -> SecCertificate? {
        guard let cerURL = self.url(forResource: name, withExtension: "cer"),
              let cerData = try? Data(contentsOf: cerURL) else {
            return nil
        }
        return SecCertificateCreateWithData(nil, cerData as CFData)
    }

    func identity(named name: String, password: String) -> SecIdentity? {
        guard let p12URL = self.url(forResource: name, withExtension: "p12"),
              let p12Data = try? Data(contentsOf: p12URL) else {
            return nil
        }

        let options = [kSecImportExportPassphrase as String: password] as CFDictionary
        var items: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options, &items)

        guard status == errSecSuccess, let itemsArray = items as? [[String: AnyObject]],
              let firstItem = itemsArray.first,
              let identity = firstItem[kSecImportItemIdentity as String] else {
            return nil
        }

        // Explanation of cross-platform behavior differences:
        // - Linux and macOS treat Core Foundation types differently.
        // - The `as? SecIdentity` casting causes a compiler error on Apple platforms as the cast is guaranteed.
        // - Directly returning `identity` works on Linux but not on macOS due to strict type expectations.
        // SwiftLint is temporarily disabled for the next line to allow a force cast, acknowledging the platform-specific behavior.
        // swiftlint:disable:next force_cast
        return (identity as! SecIdentity)
    }
}

extension SecTrust {
    enum TrustEvaluationError: Error {
        case evaluationFailed(error: CFError?)
        case evaluationIssue(error: String)
    }

    /// Evaluates the trust object synchronously and returns a Boolean value indicating whether the trust evaluation succeeded.
    func evaluate() throws -> Bool {
        var error: CFError?
        let evaluationSucceeded = SecTrustEvaluateWithError(self, &error)
        guard evaluationSucceeded else {
            throw TrustEvaluationError.evaluationFailed(error: error)
        }
        return evaluationSucceeded
    }

    /// Evaluates the trust object allowing custom root certificates, and returns a Boolean value indicating whether the evaluation succeeded.
    func evaluateAllowing(rootCertificates: [SecCertificate]) throws -> Bool {
        // Set the custom root certificates as trusted anchors.
        let status = SecTrustSetAnchorCertificates(self, rootCertificates as CFArray)
        guard status == errSecSuccess else {
            throw TrustEvaluationError.evaluationIssue(error: "Failed to set anchor certificates!")
        }

        // Consider any built-in anchors in the evaluation.
        SecTrustSetAnchorCertificatesOnly(self, false)

        // Evaluate the trust object.
        return try evaluate()
    }
}

#endif
