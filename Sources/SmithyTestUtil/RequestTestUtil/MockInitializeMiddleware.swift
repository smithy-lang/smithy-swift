//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyAPI
import SmithyStreamsAPI
import ClientRuntime

public struct MockInitializeMiddleware: Middleware {
    public typealias Context = OperationContext
    public typealias MInput = MockInput
    public typealias MOutput = OperationOutput<MockOutput>
    public typealias MockInitializeMiddlewareCallback = (OperationContext, MInput) -> Void
    public let id: String
    let callback: MockInitializeMiddlewareCallback?

    public init(id: String, callback: MockInitializeMiddlewareCallback? = nil) {
        self.id = id
        self.callback = callback
    }

    public func handle<H>(context: OperationContext, input: MInput, next: H) async throws -> MOutput
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        if let callback = self.callback {
            callback(context, input)
        }
        var copiedInput = input
        copiedInput.value = 1023

        return try await next.handle(context: context, input: copiedInput)
    }
}
