//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyAPI.OperationContext

public struct IdempotencyTokenMiddleware<OperationStackInput, OperationStackOutput>: ClientRuntime.Middleware {
    public let id: Swift.String = "IdempotencyTokenMiddleware"
    private let keyPath: WritableKeyPath<OperationStackInput, String?>

    public init(keyPath: WritableKeyPath<OperationStackInput, String?>) {
        self.keyPath = keyPath
    }

    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) async throws -> MOutput
    where H: Handler, Self.MInput == H.Input, Self.MOutput == H.Output, Self.Context == H.Context {
        let withToken = addToken(input: input, attributes: context)
        return try await next.handle(context: context, input: withToken)
    }

    private func addToken(input: OperationStackInput, attributes: OperationContext) -> OperationStackInput {
        var copiedInput = input
        if input[keyPath: keyPath] == nil {
            let idempotencyTokenGenerator = attributes.getIdempotencyTokenGenerator()
            copiedInput[keyPath: keyPath] = idempotencyTokenGenerator.generateToken()
        }
        return copiedInput
    }

    public typealias MInput = OperationStackInput
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = OperationContext
}

extension IdempotencyTokenMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeSerialization(context: some MutableInput<InputType, AttributesType>) async throws {
        let withToken = addToken(input: context.getInput(), attributes: context.getAttributes())
        context.updateInput(updated: withToken)
    }
}
