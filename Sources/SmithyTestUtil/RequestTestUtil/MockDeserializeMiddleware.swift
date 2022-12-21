//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public struct MockDeserializeMiddleware<OperationStackOutput: HttpResponseBinding,
                                 OperationStackError: HttpResponseBinding>: Middleware {
    // swiftlint:disable line_length
    public typealias MockDeserializeMiddlewareCallback = (Context,
                                                          SdkHttpRequest) async throws -> OperationOutput<OperationStackOutput>?
    public var id: String
    let callback: MockDeserializeMiddlewareCallback?

    public init(id: String, callback: MockDeserializeMiddlewareCallback? = nil) {
        self.id = id
        self.callback = callback
    }
    
    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        
        if let callback = self.callback,
           let callbackReturnValue = try await callback(context, input) {
            return callbackReturnValue
        }

        let response = try await next.handle(context: context, input: input)

        var copiedResponse = response
    
        let decoder = context.getDecoder()
        let output = try OperationStackOutput(httpResponse: copiedResponse.httpResponse, decoder: decoder)
        copiedResponse.output = output
        
        return copiedResponse

    }
    
    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}
