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
        /* TASKS IN ORDER: */
        // Retrieve resolved Auth Scheme from context
        let selectedAuthScheme = context.getSelectedAuthScheme()!
        // Don't sign and return if noAuth
        guard selectedAuthScheme.schemeId != "smithy.api#noAuth" else {
            return try await next.handle(context:context, input: input)
        }
        // Retrieve resolved Identity from context
        let identity = selectedAuthScheme.identity!
        // Retrieve correct Signer from the resolved Auth Scheme
        let signer = selectedAuthScheme.signer!
        // Construct Attributes object that has signing properties required by Signer
        let signingProperties = selectedAuthScheme.signingProperties!
        // Pass built input, identity, and signing properties to a call to Signer::Sign
        let signedInput = try await signer.sign(requestBuilder: input, identity: identity, signingProperties: signingProperties)
        // Pass along signed input to next middleware in chain
        return try await next.handle(context: context, input: signedInput)
    }
}
