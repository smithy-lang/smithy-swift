//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import ClientRuntime

public struct MockSerializeMiddleware: Middleware {
    public typealias MInput = SerializeStepInput<MockInput>
    public typealias MOutput = OperationOutput<MockOutput>
    public typealias MockSerializeMiddlewareCallback = (Context, MInput) -> Void
    public let id: String
    let headerName: String
    let headerValue: String
    let callback: MockSerializeMiddlewareCallback?

    public init(id: String,
                headerName: String,
                headerValue: String,
                callback: MockSerializeMiddlewareCallback? = nil) {
        self.id = id
        self.headerName = headerName
        self.headerValue = headerValue
        self.callback = callback
    }

    public func handle<H>(context: Context, input: MInput, next: H) async throws -> MOutput
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output {
        if let callback = self.callback {
            callback(context, input)
        }
        let path = context.path
        let method = context.method
        let host = "httpbin.org"
        input.builder.withHost(host)
            .withHeader(name: "Content-type", value: "application/json")
            .withHeader(name: headerName, value: headerValue)
            .withHeader(name: "Host", value: host)
            .withPath(path)
            .withMethod(method)

        return try await next.handle(context: context, input: input)
    }

}
