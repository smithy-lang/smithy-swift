//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import ClientRuntime

extension HttpRequestTestBase {
    typealias ConstructMockInitializeStackStepExecutionCallback<I> =
        MockMiddlewareStackStep<I, SerializeStepInput<I>>.MockMiddlewareStackStepCallbackType
    where I: Reflection, I: Encodable
    typealias ConstructMockSerializeStackStepExecutionCallback<I> =
        MockSerializeStackStep<I>.MockMiddlewareStackStepCallbackType
    where I: Reflection, I: Encodable
    typealias ConstructMockBuildStackStepExecutionCallback<I> =
        MockMiddlewareStackStep<SerializeStepInput<I>, SdkHttpRequestBuilder>.MockMiddlewareStackStepCallbackType
    where I: Reflection, I: Encodable
    typealias ConstructMockFinalizeStackStepExecutionCallback =
        MockMiddlewareStackStep<SdkHttpRequestBuilder, SdkHttpRequest>.MockMiddlewareStackStepCallbackType
    typealias ConstructMockDeserializeStackStepExecutionCallback<O, E> =
        MockMiddlewareStackStep<SdkHttpRequest, DeserializeOutput<O, E>>.MockMiddlewareStackStepCallbackType
    where O: HttpResponseBinding, E: HttpResponseBinding

    typealias ConstructMockInitializeStackStepInterceptCallback<I> =
        () -> InitializeStep<I> where I: Reflection, I: Encodable
    typealias ConstructMockBuildStackStepInterceptCallback<I> =
        () -> BuildStep<I> where I: Reflection, I: Encodable
    typealias ConstructMockFinalizeStackStepInterceptCallback =
        () -> FinalizeStep
    typealias ConstructMockDeserializeStackStepInterceptCallback<O, E> =
        () -> DeserializeStep<O, E> where O: HttpResponseBinding, E: HttpResponseBinding
    
    func constructMockInitializeStackStep<I>(_ executionCallback: ConstructMockInitializeStackStepExecutionCallback<I>? = nil,
                                             interceptCallback: ConstructMockInitializeStackStepInterceptCallback<I>? = nil)
    -> MockMiddlewareStackStep<I, SerializeStepInput<I>> {
        var step: InitializeStep<I>!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = InitializeStep<I>()
        }
        return MockMiddlewareStackStep<I, SerializeStepInput<I>>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  handler: InitializeStepHandler().eraseToAnyHandler(),
                  callback: executionCallback
            )
    }
    
    func constructMockSerializeStackStep<I>(_ executionCallback: ConstructMockSerializeStackStepExecutionCallback<I>? = nil,
                                            interceptCallback: (() -> SerializeStep<I>)? = nil) -> MockSerializeStackStep<I> {
        var step: SerializeStep<I>!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = SerializeStep<I>()
        }
        let mockStackStep = MockMiddlewareStackStep<SerializeStepInput<I>, SerializeStepInput<I>>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  handler: SerializeStepHandler().eraseToAnyHandler(),
                  callback: executionCallback
            )
        return mockStackStep
    }
    
    func constructMockBuildStackStep<I>(_ executionCallback: ConstructMockBuildStackStepExecutionCallback<I>? = nil,
                                     interceptCallback: ConstructMockBuildStackStepInterceptCallback<I>? = nil)
    -> MockMiddlewareStackStep<SerializeStepInput<I>, SdkHttpRequestBuilder> {
        var step: BuildStep<I>!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = BuildStep<I>()
        }
        let mockStackStep = MockMiddlewareStackStep<SerializeStepInput<I>, SdkHttpRequestBuilder>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  handler: BuildStepHandler().eraseToAnyHandler(),
                  callback: executionCallback
            )
        return mockStackStep
    }
    
    func constructMockFinalizeStackStep(_ executionCallback: ConstructMockFinalizeStackStepExecutionCallback? = nil,
                                        interceptCallback: ConstructMockFinalizeStackStepInterceptCallback? = nil)
    -> MockMiddlewareStackStep<SdkHttpRequestBuilder, SdkHttpRequest> {
        var step: FinalizeStep!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = FinalizeStep()
        }
        let mockStackStep = MockMiddlewareStackStep<SdkHttpRequestBuilder, SdkHttpRequest>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  handler: FinalizeStepHandler().eraseToAnyHandler(),
                  callback: executionCallback
            )
        return mockStackStep
    }
    
    func constructMockDeserializeStackStep<O, E>(_ executionCallback: ConstructMockDeserializeStackStepExecutionCallback<O, E>? = nil,
                                           interceptCallback: ConstructMockDeserializeStackStepInterceptCallback<O, E>? = nil)
    -> MockMiddlewareStackStep<SdkHttpRequest, DeserializeOutput<O, E>> {
        var step: DeserializeStep<O, E>!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = DeserializeStep()
        }
        let mockStackStep = MockMiddlewareStackStep<SdkHttpRequest, DeserializeOutput<O, E>>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  callback: executionCallback
            )
        return mockStackStep
    }
}
