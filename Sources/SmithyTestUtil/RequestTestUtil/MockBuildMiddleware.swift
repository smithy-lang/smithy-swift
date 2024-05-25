//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyAPI
import SmithyHTTPAPI
import ClientRuntime

public struct MockBuildMiddleware: Middleware {
    public typealias Context = OperationContext
    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<MockOutput>
    public typealias MockBuildMiddlewareCallback = (OperationContext, MInput) -> Void
    public let id: String
    let callback: MockBuildMiddlewareCallback?

    public init(id: String, callback: MockBuildMiddlewareCallback? = nil) {
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

        return try await next.handle(context: context, input: input)
    }
}
