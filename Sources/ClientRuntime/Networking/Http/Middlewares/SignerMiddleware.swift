//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SignerMiddleware<OperationStackOutput: HttpResponseBinding,
                               OperationStackError: HttpResponseErrorBinding>: Middleware {
    public let id: String = "SignerMiddleware"

    public init () {}

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext

    public func handle<H>(context: HttpContext,
                          input: SdkHttpRequestBuilder,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
    Self.Context == H.Context,
    Self.MInput == H.Input,
    Self.MOutput == H.Output {
        // Retrieve selected auth scheme from context
        guard let selectedAuthScheme = context.getSelectedAuthScheme() else {
            throw ClientError.authError("Auth scheme needed by signer middleware was not saved properly.")
        }

        // Return without signing request if resolved auth scheme is of noAuth type
        guard selectedAuthScheme.schemeID != "smithy.api#noAuth" else {
            return try await next.handle(context:context, input: input)
        }

        // Retrieve identity, signer, and signing properties from selected auth scheme to sign the request.
        guard let identity = selectedAuthScheme.identity else {
            throw ClientError.authError("Identity needed by signer middleware was not properly saved into loaded auth scheme.")
        }
        guard let signer = selectedAuthScheme.signer else {
            throw ClientError.authError("Signer needed by signer middleware was not properly saved into loaded auth scheme.")
        }
        guard let signingProperties = selectedAuthScheme.signingProperties else {
            throw ClientError.authError("Signing properties object needed by signer middleware was not properly saved into loaded auth scheme.")
        }

        // Sign request and hand over to next middleware (handler) in line.
        let signedInput = try await signer.sign(requestBuilder: input, identity: identity, signingProperties: signingProperties)
        return try await next.handle(context: context, input: signedInput)
    }
}
