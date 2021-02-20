//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public struct MockFinalizeMiddleware: Middleware {
    public typealias Context = HttpContext
    public typealias MOutput = OperationOutput<MockOutput, MockMiddlewareError>
    public typealias MockFinalizeMiddlewareCallback = (HttpContext, MInput) -> Void
    public let id: String
    let callback: MockFinalizeMiddlewareCallback?

    public init(id: String, callback: MockFinalizeMiddlewareCallback? = nil) {
        self.id = id
        self.callback = callback
    }
    
    public func handle<H>(context: HttpContext, input: MInput, next: H) -> Result<MOutput, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        if let callback = self.callback {
            callback(context, input)
        }
        
        return next.handle(context: context, input: input)
    }
    
    public typealias MInput = SdkHttpRequestBuilder
}
