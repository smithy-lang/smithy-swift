// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct DeserializeMiddleware<Output: HttpResponseBinding,
                                    OutputError: HttpResponseBinding>: Middleware {
    
    public var id: String = "Deserialize"
    
    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) -> Result<OperationOutput<Output, OutputError>, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        
        let decoder = context.getDecoder()
        let response = next.handle(context: context, input: input) // call handler to get http response
        return response.flatMap { (deserializeOutput) -> Result<OperationOutput<Output, OutputError>, Error> in
            var copiedResponse = deserializeOutput
            do {
                if let httpResponse = copiedResponse.httpResponse {
                    if (200..<300).contains(httpResponse.statusCode.rawValue) {
                        let output = try Output(httpResponse: httpResponse, decoder: decoder)
                        copiedResponse.output = output
                        return .success(copiedResponse)
                    } else {
                        let error = try OutputError(httpResponse: httpResponse, decoder: decoder)
                        copiedResponse.error = error
                        return .success(copiedResponse)
                    }
                } else {
                    return .failure(ClientError.unknownError("Http response was nil which should never happen"))
                }
            } catch let err {
                return .failure(ClientError.deserializationFailed(err))
            }
        }
    }
    
    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<Output, OutputError>
    public typealias Context = HttpContext
}
