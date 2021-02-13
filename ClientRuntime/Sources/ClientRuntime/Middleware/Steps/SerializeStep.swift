// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Serializes the prepared input into a data structure that can be consumed
/// by the target transport's message, (e.g. REST-JSON serialization)
///
/// Converts Input Parameters into a Request, and returns the result or error.
///
/// Receives result or error from Build step.
public typealias SerializeStep<I: Encodable & Reflection,
                               O: HttpResponseBinding,
                               E: HttpResponseBinding> = MiddlewareStep<SerializeStepInput<I>, OperationOutput<O, E>>

public struct SerializeStepHandler<OperationStackInput: Encodable & Reflection,
                                   OperationStackOutput: HttpResponseBinding,
                                   OperationStackError: HttpResponseBinding,
                                   H: Handler>: Handler where H.Context == HttpContext,
                                                              H.Input == SdkHttpRequestBuilder,
                                                              H.Output == OperationOutput<OperationStackOutput, OperationStackError> {

    public typealias Input = SerializeStepInput<OperationStackInput>
    
    public typealias Output = OperationOutput<OperationStackOutput, OperationStackError>
    
    let inner: H
    
    public init(inner: H) {
        self.inner = inner
    }
    
    public func handle(context: HttpContext, input: Input) -> Result<Output, Error> {
        return inner.handle(context: context, input: input.builder)
    }
}

public struct SerializeStepInput<OperationStackInput: Encodable & Reflection> {
    public let operationInput: OperationStackInput
    public let builder: SdkHttpRequestBuilder = SdkHttpRequestBuilder()
}
