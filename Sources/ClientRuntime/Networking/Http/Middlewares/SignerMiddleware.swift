//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import enum Smithy.ClientError
import Foundation
import SmithyHTTPAPI
import SmithyHTTPAuthAPI
import struct Smithy.AttributeKey

public struct SignerMiddleware<OperationStackOutput> {
    public let id: String = "SignerMiddleware"

    public init() {}
}

extension SignerMiddleware: ApplySigner {
    public func apply(
        request: HTTPRequest,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: Smithy.Context
    ) async throws -> HTTPRequest {
        guard let selectedAuthScheme = selectedAuthScheme else {
            throw ClientError.authError("Auth scheme needed by signer middleware was not saved properly.")
        }

        // Return without signing request if resolved auth scheme is of noAuth type
        guard selectedAuthScheme.schemeID != "smithy.api#noAuth" else {
            return request
        }

        // Retrieve identity, signer, and signing properties from selected auth scheme to sign the request.
        guard let identity = selectedAuthScheme.identity else {
            throw ClientError.authError(
                "Identity needed by signer middleware was not properly saved into loaded auth scheme."
            )
        }
        guard let signer = selectedAuthScheme.signer else {
            throw ClientError.authError(
                "Signer needed by signer middleware was not properly saved into loaded auth scheme."
            )
        }
        guard let signingProperties = selectedAuthScheme.signingProperties else {
            throw ClientError.authError(
                "Signing properties object needed by signer middleware was not properly saved into loaded auth scheme."
            )
        }

        // Check if CRT should be provided a pre-computed Sha256 SignedBodyValue
        var updatedSigningProperties = signingProperties
        let sha256: String? = attributes.get(key: AttributeKey(name: "X-Amz-Content-Sha256"))
        if let bodyValue = sha256 {
            updatedSigningProperties.set(key: AttributeKey(name: "SignedBodyValue"), value: bodyValue)
        }

        if case .stream(let stream) = request.body, stream.isEligibleForChunkedStreaming {
            // Pass in context object via signing properties to reuse final checksum value in chunked streaming.
            updatedSigningProperties.set(key: AttributeKey(name: "Context"), value: attributes)
        }

        let signed = try await signer.signRequest(
            requestBuilder: request.toBuilder(),
            identity: identity,
            signingProperties: updatedSigningProperties
        )

        // The saved signature is used to sign event stream messages if needed.
        attributes.requestSignature = signed.signature ?? ""

        return signed.build()
    }
}
