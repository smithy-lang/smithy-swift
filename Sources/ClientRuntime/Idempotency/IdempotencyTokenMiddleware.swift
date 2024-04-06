//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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

    private func addToken(input: OperationStackInput, attributes: HttpContext) -> OperationStackInput {
        var copiedInput = input
        if input[keyPath: keyPath] == nil {
            let idempotencyTokenGenerator = attributes.getIdempotencyTokenGenerator()
            copiedInput[keyPath: keyPath] = idempotencyTokenGenerator.generateToken()
        }
        return copiedInput
    }

    public typealias MInput = OperationStackInput
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}

extension IdempotencyTokenMiddleware: HttpInterceptor {
    public func modifyBeforeSerialization(context: some MutableInput<AttributesType>) async throws {
        if let input: OperationStackInput = context.getInput() {
            let withToken = addToken(input: input, attributes: context.getAttributes())
            context.updateInput(updated: withToken)
        }
    }
}
