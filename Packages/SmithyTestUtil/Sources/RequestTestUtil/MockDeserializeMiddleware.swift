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
                                                          SdkHttpRequest) -> Result<OperationOutput<OperationStackOutput>,
                                                                                    MError>?
    public var id: String
    let callback: MockDeserializeMiddlewareCallback?

    public init(id: String, callback: MockDeserializeMiddlewareCallback? = nil) {
        self.id = id
        self.callback = callback
    }
    
    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) -> Result<OperationOutput<OperationStackOutput>, MError>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context,
          Self.MError == H.MiddlewareError {
        
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
                return .failure(.client(ClientError.unknownError("Http response was nil which should never happen")))
            }
        } catch let err {
            return .failure(.client(ClientError.deserializationFailed(err)))
        }
    }
    
    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
