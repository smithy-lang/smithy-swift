//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
typealias PresignerShimHandler = (SdkHttpRequestBuilder) -> Void

struct PresignerShim<OperationStackOutput: HttpResponseBinding,
                              OperationStackError: HttpResponseBinding>: Middleware {
    public let id: String = "PresignerShim"

    private let handler: PresignerShimHandler

    init(handler: @escaping PresignerShimHandler) {
        self.handler = handler
    }
    
    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
    
    public func handle<H>(context: HttpContext,
                          input: SdkHttpRequestBuilder,
                          next: H) -> Result<OperationOutput<OperationStackOutput>, MError>
    where H: Handler,
    Self.Context == H.Context,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.MError == H.MiddlewareError {
        handler(input)
        let httpResponse = HttpResponse(body: .none, statusCode: .ok)
        let output: OperationStackOutput? = try! OperationStackOutput(httpResponse: httpResponse, decoder: nil)
        return .success(.init(httpResponse: httpResponse, output: output))
    }
}
