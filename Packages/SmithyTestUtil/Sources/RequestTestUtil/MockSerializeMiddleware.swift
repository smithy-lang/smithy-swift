//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Runtime

public struct MockSerializeMiddleware: Middleware {
    public typealias Context = HttpContext
    public typealias MInput = SerializeStepInput<MockInput>
    public typealias MOutput = OperationOutput<MockOutput>
    public typealias MError = SdkError<MockMiddlewareError>
    public typealias MockSerializeMiddlewareCallback = (HttpContext, MInput) -> Void
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
    
    public func handle<H>(context: HttpContext, input: MInput, next: H) -> Result<MOutput, MError>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context,
          Self.MError == H.MiddlewareError {
        if let callback = self.callback {
            callback(context, input)
        }
        let path = context.getPath()
        let method = context.getMethod()
        let host = "httpbin.org"
        input.builder.withHost(host)
            .withHeader(name: "Content-type", value: "application/json")
            .withHeader(name: headerName, value: headerValue)
            .withHeader(name: "Host", value: host)
            .withPath(path)
            .withMethod(method)
        
        return next.handle(context: context, input: input)
    }
 
}
