//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

public struct IdempotencyTokenMiddleware<OperationStackInput, OperationStackOutput> {
    public let id: Swift.String = "IdempotencyTokenMiddleware"
    private let keyPath: WritableKeyPath<OperationStackInput, String?>

    public init(keyPath: WritableKeyPath<OperationStackInput, String?>) {
        self.keyPath = keyPath
    }

    private func addToken(input: OperationStackInput, attributes: Smithy.Context) -> OperationStackInput {
        var copiedInput = input
        if input[keyPath: keyPath] == nil {
            let idempotencyTokenGenerator = attributes.getIdempotencyTokenGenerator()
            copiedInput[keyPath: keyPath] = idempotencyTokenGenerator.generateToken()
        }
        return copiedInput
    }
}

extension IdempotencyTokenMiddleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeSerialization(context: some MutableInput<InputType>) async throws {
        let withToken = addToken(input: context.getInput(), attributes: context.getAttributes())
        context.updateInput(updated: withToken)
    }
}
