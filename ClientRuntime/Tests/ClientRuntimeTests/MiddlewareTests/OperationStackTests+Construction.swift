//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import ClientRuntime

extension OperationStackTests {
    typealias ConstructMockInitializeStackStepExecutionCallback = MockMiddlewareStackStep<MockInput,
                                                                                          SerializeStepInput<MockInput>>.MockMiddlewareStackStepCallbackType
    typealias ConstructMockInitializeStackStepInterceptCallback = () -> InitializeStep<MockInput>

    typealias ConstructMockSerializeStackStepExecutionCallback = MockMiddlewareStackStep<SerializeStepInput<MockInput>,
                                                                                         SerializeStepInput<MockInput>>.MockMiddlewareStackStepCallbackType
    typealias ConstructMockSerializeStackStepInterceptCallback = () -> SerializeStep<MockInput>

    typealias ConstructMockBuildStackStepExecutionCallback = MockMiddlewareStackStep<SerializeStepInput<MockInput>,
                                                                                     SdkHttpRequestBuilder>.MockMiddlewareStackStepCallbackType
    typealias ConstructMockBuildStackStepInterceptCallback = () -> BuildStep<MockInput>

    typealias ConstructMockFinalizeStackStepExecutionCallback = MockMiddlewareStackStep<SdkHttpRequestBuilder,
                                                                                     SdkHttpRequest>.MockMiddlewareStackStepCallbackType
    typealias ConstructMockFinalizeStackStepInterceptCallback = () -> FinalizeStep

    typealias ConstructMockDeserializeStackStepExecutionCallback = MockMiddlewareStackStep<SdkHttpRequest,
                                                                                           DeserializeOutput<MockOutput, MockMiddlewareError>>.MockMiddlewareStackStepCallbackType
    typealias ConstructMockDeserializeStackStepInterceptCallback = () -> DeserializeStep<MockOutput, MockMiddlewareError>

    
    func constructMockInitializeStackStep(_ executionCallback: ConstructMockInitializeStackStepExecutionCallback? = nil,
                                          interceptCallback: ConstructMockInitializeStackStepInterceptCallback? = nil)
    -> MockMiddlewareStackStep<MockInput, SerializeStepInput<MockInput>> {
        var step: InitializeStep<MockInput>!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = InitializeStep<MockInput>()
        }
        let mockStackStep = MockMiddlewareStackStep<MockInput,
                                                    SerializeStepInput<MockInput>>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  handler: InitializeStepHandler().eraseToAnyHandler(),
                  callback: executionCallback
            )
        return mockStackStep
    }

    public func constructMockSerializeStackStep(_ executionCallback: ConstructMockSerializeStackStepExecutionCallback? = nil,
                                                interceptCallback: ConstructMockSerializeStackStepInterceptCallback? = nil)
    -> MockMiddlewareStackStep<SerializeStepInput<MockInput>,
                               SerializeStepInput<MockInput>>{
        var step: SerializeStep<MockInput>!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = SerializeStep<MockInput>()
        }
        let mockStackStep = MockMiddlewareStackStep<SerializeStepInput<MockInput>,
                                                             SerializeStepInput<MockInput>>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  handler: SerializeStepHandler().eraseToAnyHandler(),
                  callback: executionCallback
            )
        return mockStackStep
    }

    public func constructMockBuildStackStep(_ executionCallback: ConstructMockBuildStackStepExecutionCallback? = nil,
                                                 interceptCallback: ConstructMockBuildStackStepInterceptCallback? = nil)
    -> MockMiddlewareStackStep<SerializeStepInput<MockInput>,
                               SdkHttpRequestBuilder>{
        var step: BuildStep<MockInput>!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = BuildStep<MockInput>()
        }
        let mockStackStep = MockMiddlewareStackStep<SerializeStepInput<MockInput>,
                                                             SdkHttpRequestBuilder>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  handler: BuildStepHandler().eraseToAnyHandler(),
                  callback: executionCallback
            )
        return mockStackStep
    }

    public func constructMockFinalizeStackStep(_ executionCallback: ConstructMockFinalizeStackStepExecutionCallback? = nil,
                                                 interceptCallback: ConstructMockFinalizeStackStepInterceptCallback? = nil)
    -> MockMiddlewareStackStep<SdkHttpRequestBuilder,
                               SdkHttpRequest>{
        var step: FinalizeStep!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = FinalizeStep()
        }
        let mockStackStep = MockMiddlewareStackStep<SdkHttpRequestBuilder,
                                                         SdkHttpRequest>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  handler: FinalizeStepHandler().eraseToAnyHandler(),
                  callback: executionCallback
            )
        return mockStackStep
    }

    public func constructMockDeserializeStackStep(_ executionCallback: ConstructMockDeserializeStackStepExecutionCallback? = nil,
                                                  interceptCallback: ConstructMockDeserializeStackStepInterceptCallback? = nil)
    -> MockMiddlewareStackStep<SdkHttpRequest,
                               DeserializeOutput<MockOutput, MockMiddlewareError>>{
        var step: DeserializeStep<MockOutput, MockMiddlewareError>!
        if let interceptCallback = interceptCallback {
            step = interceptCallback()
        } else {
            step = DeserializeStep()
        }
        let mockStackStep = MockMiddlewareStackStep<SdkHttpRequest,
                                                    DeserializeOutput<MockOutput, MockMiddlewareError>>
            .init(stack: step.eraseToAnyMiddlewareStack(),
                  callback: executionCallback
            )
        return mockStackStep
    }
}
