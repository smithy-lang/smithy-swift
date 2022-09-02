//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyClientRuntime

public struct MockInitializeMiddleware: Middleware {
    public typealias Context = HttpContext
    public typealias MInput = MockInput
    public typealias MOutput = OperationOutput<MockOutput>
    public typealias MockInitializeMiddlewareCallback = (HttpContext, MInput) -> Void
    public let id: String
    let callback: MockInitializeMiddlewareCallback?

    public init(id: String, callback: MockInitializeMiddlewareCallback? = nil) {
        self.id = id
        self.callback = callback
    }
    
    public func handle<H>(context: HttpContext, input: MInput, next: H) async throws -> MOutput
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
