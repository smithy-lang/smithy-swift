//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import ClientRuntime

public typealias MockInitializeStackStep<I> = MockMiddlewareStackStep<I,
                                                                      SerializeStepInput<I>> where I: Encodable, I: Reflection
public typealias MockSerializeStackStep<I> = MockMiddlewareStackStep<SerializeStepInput<I>,
                                                                     SerializeStepInput<I>> where I: Encodable, I: Reflection
public typealias MockBuildStackStep<I> = MockMiddlewareStackStep<SerializeStepInput<I>,
                                                                 SdkHttpRequestBuilder> where I: Encodable, I: Reflection
public typealias MockFinalizeStackStep = MockMiddlewareStackStep<SdkHttpRequestBuilder,
                                                                 SdkHttpRequest>
public typealias MockDeserializeStackStep<O, E> = MockMiddlewareStackStep<SdkHttpRequest,
                                                                          OperationOutput<O, E>> where O: HttpResponseBinding, E: HttpResponseBinding

public class MockMiddlewareStackStep<OperationStackInput, OperationStackOutput>: MiddlewareStackStep<OperationStackInput, OperationStackOutput> {
    
    let callback: MockMiddlewareStackStepCallbackType?
    
    public typealias MockMiddlewareStackStepCallbackType = (Context, MInput) -> Result<MOutput, Error>
    
    init(stack: AnyMiddlewareStack<OperationStackInput, OperationStackOutput, Context>,
         handler: AnyHandler<OperationStackInput, OperationStackOutput, Context>? = nil,
         callback: MockMiddlewareStackStepCallbackType? = nil) {
        self.callback = callback
        
        super.init(stack: stack, handler: handler)
    }
    
    public override func handle<H>(context: Context, input: MInput, next: H) -> Result<MOutput, Error> where H: Handler,
                                                                                                             MInput == H.Input,
                                                                                                             MOutput == H.Output,
                                                                                                             Context == H.Context {
        if let callback = callback {
            _ = callback(context, input)
        }
        return super.handle(context: context, input: input, next: next)
    }
    
}
