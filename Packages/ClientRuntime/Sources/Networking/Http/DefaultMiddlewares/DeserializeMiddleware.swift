// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct DeserializeMiddleware<Output: HttpResponseBinding,
                                    OutputError: HttpResponseBinding>: Middleware {
    
    public var id: String = "Deserialize"
    
    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) -> Result<OperationOutput<Output>, SdkError<OutputError>>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context,
          Self.MError == H.MiddlewareError {
        
        let decoder = context.getDecoder()
        let response = next.handle(context: context, input: input) // call handler to get http response
        
        switch response {
        case .failure(let err):
            return .failure(.client(ClientError.deserializationFailed(err)))
        case .success(let result) :
            var copiedResponse = result
            do {
                if (200..<300).contains(copiedResponse.httpResponse.statusCode.rawValue) {
                    let output = try Output(httpResponse: copiedResponse.httpResponse, decoder: decoder)
                    copiedResponse.output = output
                    return .success(copiedResponse)
                } else {
                    let error = try OutputError(httpResponse: copiedResponse.httpResponse, decoder: decoder)
                    return .failure(.service(error))
                }
            } catch let err {
                return .failure(.client(ClientError.deserializationFailed(err)))
            }
        }
        
    }
    
    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<Output>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OutputError>
}
