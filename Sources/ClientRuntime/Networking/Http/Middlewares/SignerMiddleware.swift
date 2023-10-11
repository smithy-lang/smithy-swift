//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct SignerMiddleware<Output: HttpResponseBinding,
                               OutputError: HttpResponseErrorBinding>: Middleware {
    public let id: String = "Signer"

    public init () {}

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<Output>
    public typealias Context = HttpContext

    public func handle<H>(context: HttpContext,
                          input: SdkHttpRequestBuilder,
                          next: H
    ) async throws -> OperationOutput<Output>
    where H: Handler,
    Self.Context == H.Context,
    Self.MInput == H.Input,
    Self.MOutput == H.Output {
        // Retrieve selected auth scheme from context
        let selectedAuthScheme = context.getSelectedAuthScheme()!
        
        // Return without signing request if resolved auth scheme is of noAuth type
        guard selectedAuthScheme.schemeID != "smithy.api#noAuth" else {
            return try await next.handle(context:context, input: input)
        }

        let identity = selectedAuthScheme.identity!
        let signer = selectedAuthScheme.signer!
        let signingProperties = selectedAuthScheme.signingProperties!

        let signedInput = try await signer.sign(requestBuilder: input, identity: identity, signingProperties: signingProperties)
        return try await next.handle(context: context, input: signedInput)
    }
}
