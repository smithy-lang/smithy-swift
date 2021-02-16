// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

// Performs final preparations needed before sending the message. The
// message should already be complete by this stage, and is only alternated
// to meet the expectations of the recipient, (e.g. Retry and AWS SigV4
// request signing)
//
// Takes Request, and returns result or error.
//
// Receives result or error from Deserialize step.
public typealias FinalizeStep<O: HttpResponseBinding,
                              E: HttpResponseBinding> = MiddlewareStep<HttpContext, SdkHttpRequestBuilder, OperationOutput<O, E>>

public struct FinalizeStepHandler<OperationStackOutput: HttpResponseBinding,
                                  OperationStackError: HttpResponseBinding,
                                  H: Handler>: Handler where H.Context == HttpContext,
                                                             H.Input == SdkHttpRequest,
                                                             H.Output == OperationOutput<OperationStackOutput, OperationStackError> {
    
    public typealias Input = SdkHttpRequestBuilder
    
    public typealias Output = OperationOutput<OperationStackOutput, OperationStackError>
    
    let inner: H
    
    public init(inner: H) {
        self.inner = inner
    }
    
    public func handle(context: HttpContext, input: Input) -> Result<Output, Error> {
        return inner.handle(context: context, input: input.build())
    }
}
