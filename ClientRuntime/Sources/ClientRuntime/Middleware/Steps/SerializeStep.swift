// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Serializes the prepared input into a data structure that can be consumed
/// by the target transport's message, (e.g. REST-JSON serialization)
///
/// Converts Input Parameters into a Request, and returns the result or error.
///
/// Receives result or error from Build step.
public struct SerializeStep<OperationStackInput>: MiddlewareStack where OperationStackInput: Encodable, OperationStackInput: Reflection {
    public typealias Context = HttpContext
    public var orderedMiddleware: OrderedGroup<SerializeStepInput<OperationStackInput>,
                                               SerializeStepInput<OperationStackInput>,
                                               HttpContext> = OrderedGroup<SerializeStepInput<OperationStackInput>,
                                                                           SerializeStepInput<OperationStackInput>,
                                                                           HttpContext>()
    
    public var id: String = "SerializeStep"
    
    public typealias MInput = SerializeStepInput<OperationStackInput>
    
    public typealias MOutput = SerializeStepInput<OperationStackInput>
    
    public init() {}
}

public struct SerializeStepHandler<OperationStackInput>: Handler where OperationStackInput: Encodable, OperationStackInput: Reflection {

    public typealias Input = SerializeStepInput<OperationStackInput>
    
    public typealias Output = SerializeStepInput<OperationStackInput>
    
    public init() {}
    
    public func handle(context: HttpContext, input: Input) -> Result<SerializeStepInput<OperationStackInput>, Error> {
        return .success(input)
    }
}

public struct SerializeStepInput<OperationStackInput> where OperationStackInput: Encodable, OperationStackInput: Reflection {
    public let operationInput: OperationStackInput
    public let builder: SdkHttpRequestBuilder = SdkHttpRequestBuilder()
}
