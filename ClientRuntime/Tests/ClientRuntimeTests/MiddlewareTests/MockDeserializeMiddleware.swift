// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

@testable import ClientRuntime

struct MockDeserializeMiddleware<Output: HttpResponseBinding,
                                 OutputError: HttpResponseBinding>: Middleware where OutputError: Error{
    var id: String
    
    func handle<H>(context: Context, input: SdkHttpRequest, next: H) -> Result<DeserializeOutput<Output, OutputError>, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {

        let response = next.handle(context: context, input: input)
        do {
            let successResponse = try response.get()
            var copiedResponse = successResponse
            if let httpResponse = copiedResponse.httpResponse {
                let decoder = context.getDecoder()
                let output = try Output(httpResponse: httpResponse, decoder: decoder)
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
    typealias MOutput = DeserializeOutput<Output, OutputError>
    typealias Context = HttpContext
}
