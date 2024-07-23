//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class AwsCommonRuntimeKit.HTTPRequestBase
import class AwsCommonRuntimeKit.Signer
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import enum AwsCommonRuntimeKit.CommonRunTimeError
import enum Smithy.ClientError
import enum SmithyHTTPAuthAPI.AWSSignedBodyHeader
import enum SmithyHTTPAuthAPI.AWSSignedBodyValue
import enum SmithyHTTPAuthAPI.AWSSignatureType
import enum SmithyHTTPAuthAPI.SigningAlgorithm
import enum SmithyHTTPAuthAPI.SigningPropertyKeys
import protocol SmithyIdentity.AWSCredentialIdentityResolver
import protocol SmithyIdentityAPI.Identity
import protocol SmithyHTTPAuthAPI.Signer
import struct AwsCommonRuntimeKit.SigningConfig
import struct Smithy.AttributeKey
import struct Smithy.Attributes
import struct Smithy.SwiftLogger
import struct SmithyIdentity.AWSCredentialIdentity
import struct SmithyHTTPAuthAPI.SigningFlags
import struct Foundation.Date
import struct Foundation.TimeInterval
import struct Foundation.URL
import SmithyHTTPClient

public class SigV4Signer: SmithyHTTPAuthAPI.Signer {
    public init() {}

    func signRequest<IdentityT>(
        requestBuilder: SmithyHTTPAPI.HTTPRequestBuilder,
        identity: IdentityT,
        signingProperties: Smithy.Attributes
    ) async throws -> SmithyHTTPAPI.HTTPRequestBuilder where IdentityT : SmithyIdentityAPI.Identity {
        guard let isBidirectionalStreamingEnabled = signingProperties.get(
            key: SigningPropertyKeys.bidirectionalStreaming
        ) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain T/F flag for bidirectional streaming."
            )
        }

        guard let identity = identity as? AWSCredentialIdentity else {
            throw Smithy.ClientError.authError(
                "Identity passed to the AWSSigV4Signer must be of type Credentials."
            )
        }

        var signingConfig = try constructSigningConfig(identity: identity, signingProperties: signingProperties)

        let unsignedRequest = requestBuilder.build()
        let crtUnsignedRequest: HTTPRequestBase = isBidirectionalStreamingEnabled ?
            try unsignedRequest.toHttp2Request() :
            try unsignedRequest.toHttpRequest()

        let crtSigningConfig = try signingConfig.toCRTType()

        let crtSignedRequest = try await Signer.signRequest(
            request: crtUnsignedRequest,
            config: crtSigningConfig
        )

        let sdkSignedRequest = requestBuilder.update(from: crtSignedRequest, originalRequest: unsignedRequest)

        // Return signed request
        return sdkSignedRequest
    }

    private func constructSigningConfig(
        identity: AWSCredentialIdentity,
        signingProperties: Smithy.Attributes
    ) throws -> AWSSigningConfig {
        guard let unsignedBody = signingProperties.get(key: SigningPropertyKeys.unsignedBody) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain T/F flag for unsigned body."
            )
        }
        guard let signingName = signingProperties.get(key: SigningPropertyKeys.signingName) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain signing name."
            )
        }
        guard let signingRegion = signingProperties.get(key: SigningPropertyKeys.signingRegion) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain signing region."
            )
        }
        guard let signingAlgorithm = signingProperties.get(key: SigningPropertyKeys.signingAlgorithm) else {
            throw Smithy.ClientError.authError(
                "Signing properties passed to the AWSSigV4Signer must contain signing algorithm."
            )
        }

        let expiration: TimeInterval = signingProperties.get(key: SigningPropertyKeys.expiration) ?? 0
        let signedBodyHeader: AWSSignedBodyHeader =
            signingProperties.get(key: SigningPropertyKeys.signedBodyHeader) ?? .none

        // Determine signed body value
        let checksumIsPresent = signingProperties.get(key: SigningPropertyKeys.checksum) != nil
        let isChunkedEligibleStream = signingProperties.get(key: SigningPropertyKeys.isChunkedEligibleStream) ?? false
        let preComputedSha256 = signingProperties.get(key: AttributeKey<String>(name: "SignedBodyValue"))

        let signedBodyValue: AWSSignedBodyValue = determineSignedBodyValue(
            checksumIsPresent: checksumIsPresent,
            isChunkedEligbleStream: isChunkedEligibleStream,
            isUnsignedBody: unsignedBody,
            preComputedSha256: preComputedSha256
        )

        let flags: SigningFlags = SigningFlags(
            useDoubleURIEncode: signingProperties.get(key: SigningPropertyKeys.useDoubleURIEncode) ?? true,
            shouldNormalizeURIPath: signingProperties.get(key: SigningPropertyKeys.shouldNormalizeURIPath) ?? true,
            omitSessionToken: signingProperties.get(key: SigningPropertyKeys.omitSessionToken) ?? false
        )
        let signatureType: AWSSignatureType =
            signingProperties.get(key: SigningPropertyKeys.signatureType) ?? .requestHeaders

        return AWSSigningConfig(
            credentials: identity,
            expiration: expiration,
            signedBodyHeader: signedBodyHeader,
            signedBodyValue: signedBodyValue,
            flags: flags,
            date: Date(),
            service: signingName,
            region: signingRegion,
            signatureType: signatureType,
            signingAlgorithm: signingAlgorithm
        )
    }

    private func determineSignedBodyValue(
        checksumIsPresent: Bool,
        isChunkedEligbleStream: Bool,
        isUnsignedBody: Bool,
        preComputedSha256: String?
    ) -> AWSSignedBodyValue {
        if !isChunkedEligbleStream {
            // Normal Payloads, Event Streams, etc.
            if isUnsignedBody {
                return .unsignedPayload
            } else if let sha256 = preComputedSha256 {
                return .precomputed(sha256)
            } else {
                return .empty
            }
        }

        // streaming + eligible for chunked transfer
        if !checksumIsPresent {
            return isUnsignedBody ? .unsignedPayload : .streamingSha256Payload
        } else {
            // checksum is present
            return isUnsignedBody ? .streamingUnsignedPayloadTrailer : .streamingSha256PayloadTrailer
        }
    }
}
