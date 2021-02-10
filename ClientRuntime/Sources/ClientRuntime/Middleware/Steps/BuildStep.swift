// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Adds additional metadata to the serialized transport message,
/// (e.g. HTTP's Content-Length header, or body checksum). Decorations and
/// modifications to the message should be copied to all message attempts.
///
/// Takes Request, and returns result or error.
///
/// Receives result or error from Finalize step.
public struct BuildStep<OperationStackInput>: MiddlewareStack where OperationStackInput: Encodable, OperationStackInput: Reflection {
    
    public typealias Context = HttpContext

    public var orderedMiddleware: OrderedGroup<SerializeStepInput<OperationStackInput>,
                                               SdkHttpRequestBuilder,
                                               HttpContext> = OrderedGroup<SerializeStepInput<OperationStackInput>,
                                                                           SdkHttpRequestBuilder,
                                                                           HttpContext>()
    
    public var id: String = "BuildStep"
    
    public typealias MInput = SerializeStepInput<OperationStackInput>
    
    public typealias MOutput = SdkHttpRequestBuilder
    
    public init() {}
}

public struct BuildStepHandler<OperationStackInput>: Handler where OperationStackInput: Encodable, OperationStackInput: Reflection {

    public typealias Input = SerializeStepInput<OperationStackInput>
    
    public typealias Output = SdkHttpRequestBuilder
    
    public init() {}
    
    public func handle(context: HttpContext, input: Input) -> Result<SdkHttpRequestBuilder, Error> {
        // since types don't change in input and output here just return the result to kick of the next step
        return .success(input.builder)
    }
}
