// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.SdkHttpRequestBuilder
import class SmithyHTTPAPI.HttpResponse

// Performs final preparations needed before sending the message. The
// message should already be complete by this stage, and is only alternated
// to meet the expectations of the recipient, (e.g. Retry and AWS SigV4
// request signing)
//
// Takes Request, and returns result or error.
//
// Receives result or error from Deserialize step.
public typealias FinalizeStep<OperationStackOutput> = MiddlewareStep<SdkHttpRequestBuilder,
                                                                     OperationOutput<OperationStackOutput>>

public let FinalizeStepId = "Finalize"

public struct FinalizeStepHandler<OperationStackOutput, H: Handler>: Handler
    where H.Input == SdkHttpRequest,
          H.Output == OperationOutput<OperationStackOutput> {

    public typealias Input = SdkHttpRequestBuilder

    public typealias Output = OperationOutput<OperationStackOutput>

    let handler: H

    public init(handler: H) {
        self.handler = handler
    }

    public func handle(context: Smithy.Context, input: Input) async throws -> Output {
        return try await handler.handle(context: context, input: input.build())
    }
}
