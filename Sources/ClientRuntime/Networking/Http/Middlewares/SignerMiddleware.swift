//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyAPI.OperationContext
import Foundation
import SmithyHTTPAPI
import SmithyHTTPAuthAPI

public struct SignerMiddleware<OperationStackOutput>: Middleware {
    public let id: String = "SignerMiddleware"

    public init () {}

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = OperationContext

    public func handle<H>(context: OperationContext,
                          input: SdkHttpRequestBuilder,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
    Self.Context == H.Context,
    Self.MInput == H.Input,
    Self.MOutput == H.Output {
        // Retrieve selected auth scheme from context
        let selectedAuthScheme = context.getSelectedAuthScheme()
        let signed = try await apply(
            request: input.build(),
            selectedAuthScheme: selectedAuthScheme,
            attributes: context
        )
        return try await next.handle(context: context, input: signed.toBuilder())
    }
}

extension SignerMiddleware: ApplySigner {
    public func apply(
        request: SdkHttpRequest,
        selectedAuthScheme: SelectedAuthScheme?,
        attributes: OperationContext
    ) async throws -> SdkHttpRequest {
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

        let signed = try await signer.signRequest(
            requestBuilder: request.toBuilder(),
            identity: identity,
            signingProperties: signingProperties
        )

        // The saved signature is used to sign event stream messages if needed.
        attributes.requestSignature = signed.signature

        return signed.build()
    }
}
