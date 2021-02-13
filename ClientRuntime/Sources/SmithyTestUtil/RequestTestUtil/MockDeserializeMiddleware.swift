//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public struct MockDeserializeMiddleware<OperationStackOutput: HttpResponseBinding,
                                 OperationStackError: HttpResponseBinding>: Middleware {
    public typealias MockDeserializeMiddlewareCallback = (Context, SdkHttpRequest) -> Result<OperationOutput<OperationStackOutput, OperationStackError>, Error>?
    public var id: String
    let callback: MockDeserializeMiddlewareCallback?

    public init(id: String, callback: MockDeserializeMiddlewareCallback? = nil) {
        self.id = id
        self.callback = callback
    }
    
    public func handle<H>(context: Context, input: SdkHttpRequest, next: H) -> Result<OperationOutput<OperationStackOutput, OperationStackError>, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        
        if let callback = self.callback,
           let callbackReturnValue = callback(context, input) {
            return callbackReturnValue
        }

        let response = next.handle(context: context, input: input)
        do {
            let successResponse = try response.get()
            var copiedResponse = successResponse
            if let httpResponse = copiedResponse.httpResponse {
                let decoder = context.getDecoder()
                let output = try OperationStackOutput(httpResponse: httpResponse, decoder: decoder)
                copiedResponse.output = output
                
                return .success(copiedResponse)
            } else {
                return .failure(ClientError.unknownError("Http response was nil which should never happen"))
            }
        } catch let err {
            return .failure(ClientError.deserializationFailed(err))
        }
    }
    
    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<OperationStackOutput, OperationStackError>
    public typealias Context = HttpContext
}
