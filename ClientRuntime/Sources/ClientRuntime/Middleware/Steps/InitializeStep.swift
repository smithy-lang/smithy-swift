// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public struct InitializeStep<Input: HttpRequestBinding>: MiddlewareStack {
    
    public typealias Context = HttpContext
    
    
    public var orderedMiddleware: OrderedGroup<Input,
                                               SdkHttpRequestBuilder,
                                               HttpContext> = OrderedGroup<Input, SdkHttpRequestBuilder, HttpContext>()
    
    public var id: String = "InitializeStep"
    
    public typealias MInput = Input
    
    public typealias MOutput = SdkHttpRequestBuilder

}

public struct InitializeStepHandler<Input: HttpRequestBinding>: Handler {    
    
    public typealias Input = Input
    
    public typealias Output = SdkHttpRequestBuilder
    
    public func handle(context: HttpContext, input: Input) -> Result<SdkHttpRequestBuilder, Error> {
        //this step takes an input of whatever type with conformance to our http binding protocol and converts it to an sdk request builder
        var copiedInput = input
        let method = context.getMethod()
        let path = context.getPath()
        let encoder = context.getEncoder()
        do {
            let sdkRequestBuilder = try copiedInput.buildHttpRequest(method: method, path: path, encoder: encoder)
            return .success(sdkRequestBuilder)
        } catch let err {
            let error = ClientError.serializationFailed(err.localizedDescription)
            return .failure(error)
        }
    }
}
