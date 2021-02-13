// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Adds additional metadata to the serialized transport message,
/// (e.g. HTTP's Content-Length header, or body checksum). Decorations and
/// modifications to the message should be copied to all message attempts.
///
/// Takes Request, and returns result or error.
///
/// Receives result or error from Finalize step.
public typealias BuildStep<O: HttpResponseBinding,
                           E: HttpResponseBinding> = MiddlewareStep<SdkHttpRequestBuilder, OperationOutput<O, E>>

public struct BuildStepHandler<OperationStackOutput: HttpResponseBinding,
                               OperationStackError: HttpResponseBinding,
                               H: Handler>: Handler where H.Context == HttpContext,
                                                          H.Input == SdkHttpRequestBuilder,
                                                          H.Output == OperationOutput<OperationStackOutput, OperationStackError> {

    public typealias Input = SdkHttpRequestBuilder
    
    public typealias Output = OperationOutput<OperationStackOutput, OperationStackError>
    
    let inner: H
    
    public init(inner: H) {
        self.inner = inner
    }
    
    public func handle(context: HttpContext, input: Input) -> Result<Output, Error> {
        return inner.handle(context: context, input: input)
    }
}
