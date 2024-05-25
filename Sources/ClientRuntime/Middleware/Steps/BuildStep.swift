// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class SmithyAPI.OperationContext
import class SmithyHTTPAPI.SdkHttpRequestBuilder

/// Adds additional metadata to the serialized transport message,
/// (e.g. HTTP's Content-Length header, or body checksum). Decorations and
/// modifications to the message should be copied to all message attempts.
///
/// Takes Request, and returns result or error.
///
/// Receives result or error from Finalize step.
public typealias BuildStep<OperationStackOutput> = MiddlewareStep<OperationContext,
                                                                  SdkHttpRequestBuilder,
                                                                  OperationOutput<OperationStackOutput>>

public let BuildStepId = "Build"

public struct BuildStepHandler<OperationStackOutput, H: Handler>: Handler
    where H.Context == OperationContext,
          H.Input == SdkHttpRequestBuilder,
          H.Output == OperationOutput<OperationStackOutput> {

    public typealias Input = SdkHttpRequestBuilder

    public typealias Output = OperationOutput<OperationStackOutput>

    let handler: H

    public init(handler: H) {
        self.handler = handler
    }

    public func handle(context: OperationContext, input: Input) async throws -> Output {
        return try await handler.handle(context: context, input: input)
    }
}
