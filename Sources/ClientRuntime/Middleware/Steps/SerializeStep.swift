// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context
import class SmithyHTTPAPI.HTTPRequestBuilder

/// Serializes the prepared input into a data structure that can be consumed
/// by the target transport's message, (e.g. REST-JSON serialization)
///
/// Converts Input Parameters into a Request, and returns the result or error.
///
/// Receives result or error from Build step.
public typealias SerializeStep<OperationStackInput, OperationStackOutput> =
    MiddlewareStep<SerializeStepInput<OperationStackInput>, OperationOutput<OperationStackOutput>>

public let SerializeStepId = "Serialize"

public struct SerializeStepHandler<OperationStackInput, OperationStackOutput, H: Handler>: Handler
    where H.Input == HTTPRequestBuilder,
          H.Output == OperationOutput<OperationStackOutput> {

    public typealias Input = SerializeStepInput<OperationStackInput>

    public typealias Output = OperationOutput<OperationStackOutput>

    let handler: H

    public init(handler: H) {
        self.handler = handler
    }

    public func handle(context: Smithy.Context, input: Input) async throws -> Output {
        return try await handler.handle(context: context, input: input.builder)
    }
}

public struct SerializeStepInput<OperationStackInput> {
    public let operationInput: OperationStackInput
    public let builder: HTTPRequestBuilder = HTTPRequestBuilder()
}
