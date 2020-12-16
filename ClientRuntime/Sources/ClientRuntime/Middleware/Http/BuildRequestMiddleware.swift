// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

public struct BuildRequestMiddleware<Input: HttpRequestBinding>: Middleware {
    
    public var id: String = "BuildRequest"
    
    let input: Input
    
    public init(input: Input) {
        self.input = input
    }
    
    public func handle<H>(context: HttpRequestContext, result: Result<SdkHttpRequest, ClientError>, next: H) -> Result<SdkHttpRequest, ClientError> where H: Handler, Self.TContext == H.TContext, Self.TError == H.TError, Self.TSubject == H.TSubject {
        let method = context.getMethod()
        let path = context.getPath()
        let encoder = context.getEncoder()
        do {
            let sdkRequest = try input.buildHttpRequest(method: method, path: path, encoder: encoder)
            return next.handle(context: context, result: .success(sdkRequest))
        } catch let err {
            let error = ClientError.serializationFailed(err.localizedDescription)
            return next.handle(context: context, result: .failure(error))
        }
    }
    
    public typealias TContext = HttpRequestContext
    
    public typealias TSubject = SdkHttpRequest
    
    public typealias TError = ClientError
}
