// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Serializes the prepared input into a data structure that can be consumed
/// by the target transport's message, (e.g. REST-JSON serialization)
///
/// Converts Input Parameters into a Request, and returns the result or error.
///
/// Receives result or error from Build step.
public typealias SerializeStep<Input, Output> =
    MiddlewareStep<HttpContext, SerializeStepInput<Input>, OperationOutput<Output>>

public let SerializeStepId = "Serialize"

public struct SerializeStepHandler<OperationStackInput,
                                   OperationStackOutput,
                                   H: Handler>: Handler where H.Context == HttpContext,
                                                              H.Input == SdkHttpRequestBuilder,
                                                              H.Output == OperationOutput<OperationStackOutput> {

    public typealias Input = SerializeStepInput<OperationStackInput>

    public typealias Output = OperationOutput<OperationStackOutput>

    let handler: H

    public init(handler: H) {
        self.handler = handler
    }

    public func handle(context: HttpContext, input: Input) async throws -> Output {
        return try await handler.handle(context: context, input: input.builder)
    }
}

public struct SerializeStepInput<OperationStackInput> {
    public let operationInput: OperationStackInput
    public let builder: SdkHttpRequestBuilder = SdkHttpRequestBuilder()
}
