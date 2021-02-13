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
                                 E: HttpResponseBinding> = MiddlewareStep<SdkHttpRequest, OperationOutput<O, E>>

public struct DeserializeStepHandler<OperationStackOutput: HttpResponseBinding,
                                     OperationStackError: HttpResponseBinding,
                                     H: Handler>: Handler where H.Context == HttpContext,
                                                                H.Input == SdkHttpRequest,
                                                                H.Output == OperationOutput<OperationStackOutput, OperationStackError> {
    
    public typealias Input = SdkHttpRequest
    
    public typealias Output = OperationOutput<OperationStackOutput, OperationStackError>
    
    let inner: H
    
    public init(inner: H) {
        self.inner = inner
    }
    
    public func handle(context: HttpContext, input: Input) -> Result<Output, Error> {
       return inner.handle(context: context, input: input)
    }
}

public struct OperationOutput<Output: HttpResponseBinding, OutputError: HttpResponseBinding> {
    public var httpResponse: HttpResponse?
    public var output: Output?
    public var error: OutputError?
    public init(httpResponse: HttpResponse? = nil, output: Output? = nil, error: OutputError? = nil) {
        self.httpResponse = httpResponse
        self.output = output
        self.error = error
    }
}
