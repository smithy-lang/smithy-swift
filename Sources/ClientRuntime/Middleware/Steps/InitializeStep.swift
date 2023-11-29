// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public typealias InitializeStep<Input,
                                Output> = MiddlewareStep<HttpContext,
                                                         Input,
                                                         OperationOutput<Output>>

public let InitializeStepId = "Initialize"

public struct InitializeStepHandler<OperationStackInput,
                                    OperationStackOutput,
                                    H: Handler>: Handler where H.Context == HttpContext,
                                                               H.Input == SerializeStepInput<OperationStackInput>,
                                                               H.Output == OperationOutput<OperationStackOutput> {

    public typealias Input = OperationStackInput

    public typealias Output = OperationOutput<OperationStackOutput>

    let handler: H

    public init(handler: H) {
        self.handler = handler
    }

    public func handle(context: HttpContext, input: Input) async throws -> Output {
        let serializeInput = SerializeStepInput<OperationStackInput>(operationInput: input)

        return try await handler.handle(context: context, input: serializeInput)
    }
}
