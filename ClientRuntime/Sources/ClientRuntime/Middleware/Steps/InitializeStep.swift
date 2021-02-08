// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public struct InitializeStep<Input>: MiddlewareStack {
    
    public typealias Context = HttpContext
    
    public var orderedMiddleware: OrderedGroup<Input,
                                               Input,
                                               HttpContext> = OrderedGroup<Input,
                                                                           Input,
                                                                           HttpContext>()
    
    public var id: String = "InitializeStep"
    
    public typealias MInput = Input
    
    public typealias MOutput = Input
    
    public init() {}

}

public struct InitializeStepHandler<Input>: Handler {
    
    public typealias Input = Input
    
    public typealias Output = Input
    
    public init() {}
    
    public func handle(context: HttpContext, input: Input) -> Result<Input, Error> {
        // this step takes an input of whatever type with conformance to our http binding protocol
        // and converts it to an sdk request builder
        return .success(input)
//        let encoder = context.getEncoder()
//        do {
//            let sdkRequestBuilder = try input.buildHttpRequest(encoder: encoder,
//                                                               idempotencyTokenGenerator:
//                                                                DefaultIdempotencyTokenGenerator())
//            return .success(sdkRequestBuilder)
//        } catch let err {
//            let error = ClientError.serializationFailed(err.localizedDescription)
//            return .failure(error)
//        }
    }
}
