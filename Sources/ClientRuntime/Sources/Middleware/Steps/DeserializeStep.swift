// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Reacts to the handler's response returned by the recipient of the request
/// message. Deserializes the response into a structured type or error above
/// stacks can react to.
///
/// Should only forward Request to underlying handler.
///
/// Takes Request, and returns result or error.
///
/// Receives raw response, or error from underlying handler.
public typealias DeserializeStep<O: HttpResponseBinding,
                                 E: HttpResponseBinding> = MiddlewareStep<HttpContext,
                                                                          SdkHttpRequest,
                                                                          OperationOutput<O>,
                                                                          SdkError<E>>

public let DeserializeStepId = "Deserialize"

public struct DeserializeStepHandler<OperationStackOutput: HttpResponseBinding,
                                     OperationStackError: HttpResponseBinding,
                                     H: Handler>: Handler where H.Context == HttpContext,
                                                                H.Input == SdkHttpRequest,
                                                                H.Output == OperationOutput<OperationStackOutput>,
                                                                H.MiddlewareError == SdkError<OperationStackError> {
    
    public typealias Input = SdkHttpRequest
    
    public typealias Output = OperationOutput<OperationStackOutput>
    
    public typealias MiddlewareError = SdkError<OperationStackError>
    
    let handler: H
    
    public init(handler: H) {
        self.handler = handler
    }
    
    public func handle(context: HttpContext, input: Input) -> Result<Output, MiddlewareError> {
       return handler.handle(context: context, input: input)
    }
}

public struct OperationOutput<Output: HttpResponseBinding> {
    public var httpResponse: HttpResponse
    public var output: Output?
    
    public init(httpResponse: HttpResponse, output: Output? = nil) {
        self.httpResponse = httpResponse
        self.output = output
    }
}
