// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

@testable import ClientRuntime

struct MockDeserializeMiddleware<OperationStackOutput: HttpResponseBinding,
                                 OperationStackError: HttpResponseBinding>: Middleware where OperationStackError: Error{
    typealias MockDeserializeMiddlewareCallback = (Context, SdkHttpRequest) -> Void
    var id: String
    let callback: MockDeserializeMiddlewareCallback?

    init(id: String, callback: MockDeserializeMiddlewareCallback? = nil) {
        self.id = id
        self.callback = callback
    }
    
    func handle<H>(context: Context, input: SdkHttpRequest, next: H) -> Result<DeserializeOutput<OperationStackOutput, OperationStackError>, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        
        if let callback = self.callback {
            callback(context, input)
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
    
    typealias MInput = SdkHttpRequest
    typealias MOutput = DeserializeOutput<OperationStackOutput, OperationStackError>
    typealias Context = HttpContext
}
