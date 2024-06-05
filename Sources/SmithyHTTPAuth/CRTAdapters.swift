//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum AwsCommonRuntimeKit.SigningAlgorithmType
import enum AwsCommonRuntimeKit.SignedBodyHeaderType
import enum AwsCommonRuntimeKit.SignedBodyValue
import enum AwsCommonRuntimeKit.SignatureType
import struct AwsCommonRuntimeKit.SigningConfig

import enum SmithyHTTPAuthAPI.SigningAlgorithm
import enum SmithyHTTPAuthAPI.AWSSignedBodyHeader
import enum SmithyHTTPAuthAPI.AWSSignedBodyValue
import enum SmithyHTTPAuthAPI.AWSSignatureType

import struct Foundation.Locale
import class SmithyIdentity.CRTAWSCredentialIdentity

extension SigningAlgorithm {
    /// Convert self to CRT SigningAlgorithmType
    /// - Returns: SigningAlgorithmType
    public func toCRTType() -> SigningAlgorithmType {
        switch self {
        case .sigv4: return .signingV4
        case .sigv4a: return .signingV4Asymmetric
        }
    }
}

extension AWSSignatureType {
    public func toCRTType() -> SignatureType {
        switch self {
        case .requestChunk: return .requestChunk
        case .requestHeaders: return .requestHeaders
        case .requestQueryParams: return .requestQueryParams
        case .requestTrailingHeaders: return .requestTrailingHeaders
        case .requestEvent: return .requestEvent
        }
    }
}

extension AWSSignedBodyHeader {
    func toCRTType() -> SignedBodyHeaderType {
        switch self {
        case .none: return .none
        case .contentSha256: return .contentSha256
        }
    }
}

extension AWSSignedBodyValue {
    func toCRTType() -> SignedBodyValue {
        switch self {
        case .empty: return .empty
        case .emptySha256: return .emptySha256
        case .unsignedPayload: return .unsignedPayload
        case .streamingSha256Payload: return .streamingSha256Payload
        case .streamingSha256Events: return .streamingSha256Events
        case .streamingSha256PayloadTrailer: return .streamingSha256PayloadTrailer
        case .streamingUnsignedPayloadTrailer: return .streamingUnSignedPayloadTrailer
        }
    }
}

extension AWSSigningConfig {
    public func toCRTType() throws -> SigningConfig {
        // Never include the Transfer-Encoding header in the signature,
        // since older versions of URLSession will modify this header's value
        // prior to sending a request.
        //
        // The Transfer-Encoding header does not affect the AWS operation being
        // performed and is just there to coordinate the flow of data to the server.
        //
        // For all other headers, use the shouldSignHeaders block that was passed to
        // determine if the header should be included in the signature.  If the
        // shouldSignHeaders block was not provided, then include all headers other
        // than Transfer-Encoding.
        let modifiedShouldSignHeader = { (name: String) in
            guard name.lowercased(with: Locale(identifier: "en_US_POSIX")) != "transfer-encoding" else { return false }
            return shouldSignHeader?(name) ?? true
        }

        return SigningConfig(
            algorithm: signingAlgorithm.toCRTType(),
            signatureType: signatureType.toCRTType(),
            service: service,
            region: region,
            date: date,
            credentials: try credentials.map { try CRTAWSCredentialIdentity(awsCredentialIdentity: $0) },
            credentialsProvider: try awsCredentialIdentityResolver?.getCRTAWSCredentialIdentityResolver(),
            expiration: expiration,
            signedBodyHeader: signedBodyHeader.toCRTType(),
            signedBodyValue: signedBodyValue.toCRTType(),
            shouldSignHeader: modifiedShouldSignHeader,
            useDoubleURIEncode: flags.useDoubleURIEncode,
            shouldNormalizeURIPath: flags.shouldNormalizeURIPath,
            omitSessionToken: flags.omitSessionToken
        )
    }
}
