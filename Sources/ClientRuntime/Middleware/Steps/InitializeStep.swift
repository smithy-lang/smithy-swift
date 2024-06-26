// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public typealias InitializeStep<OperationStackInput, OperationStackOutput> =
    MiddlewareStep<OperationStackInput, OperationOutput<OperationStackOutput>>

public let InitializeStepId = "Initialize"

public struct InitializeStepHandler<OperationStackInput, OperationStackOutput, H: Handler>: Handler
    where H.Input == SerializeStepInput<OperationStackInput>,
          H.Output == OperationOutput<OperationStackOutput> {

    public typealias Input = OperationStackInput

    public typealias Output = OperationOutput<OperationStackOutput>

    let handler: H

    public init(handler: H) {
        self.handler = handler
    }

    public func handle(context: Smithy.Context, input: Input) async throws -> Output {
        let serializeInput = SerializeStepInput<OperationStackInput>(operationInput: input)

        return try await handler.handle(context: context, input: serializeInput)
    }
}
