// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Serializes the prepared input into a data structure that can be consumed
/// by the target transport's message, (e.g. REST-JSON serialization)
///
/// Converts Input Parameters into a Request, and returns the result or error.
///
/// Receives result or error from Build step.
public struct SerializeStep<OperationInput>: MiddlewareStack {
    public typealias Context = HttpContext
    
    public var orderedMiddleware: OrderedGroup<SerializeStepInput<OperationInput>,
                                               SerializeStepInput<OperationInput>,
                                               HttpContext> = OrderedGroup<SerializeStepInput<OperationInput>,
                                                                           SerializeStepInput<OperationInput>,
                                                                           HttpContext>()
    
    public var id: String = "SerializeStep"
    
    public typealias MInput = SerializeStepInput<OperationInput>
    
    public typealias MOutput = SerializeStepInput<OperationInput>
    
    public init() {}
}

public struct SerializeStepHandler<OperationInput>: Handler {
    
    public typealias Input = SerializeStepInput<OperationInput>
    
    public typealias Output = SerializeStepInput<OperationInput>
    
    public init() {}
    
    public func handle(context: HttpContext, input: Input) -> Result<SerializeStepInput<OperationInput>, Error> {
        // this step does not change types from input and output so just return the input as the result
        return .success(input)
    }
}

public struct SerializeStepInput<OperationInput> {
    public let operationInput: OperationInput
    public let builder: SdkHttpRequestBuilder = SdkHttpRequestBuilder()
}
