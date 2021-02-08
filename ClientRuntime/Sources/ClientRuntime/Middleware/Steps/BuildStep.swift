// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Adds additional metadata to the serialized transport message,
/// (e.g. HTTP's Content-Length header, or body checksum). Decorations and
/// modifications to the message should be copied to all message attempts.
///
/// Takes Request, and returns result or error.
///
/// Receives result or error from Finalize step.
public struct BuildStep<OperationInput>: MiddlewareStack {
    
    public typealias Context = HttpContext

    public var orderedMiddleware: OrderedGroup<SerializeStepInput<OperationInput>,
                                               SdkHttpRequestBuilder,
                                               HttpContext> = OrderedGroup<SerializeStepInput<OperationInput>,
                                                                           SdkHttpRequestBuilder,
                                                                           HttpContext>()
    
    public var id: String = "BuildStep"
    
    public typealias MInput = SerializeStepInput<OperationInput>
    
    public typealias MOutput = SdkHttpRequestBuilder
    
    public init() {}
}

public struct BuildStepHandler<OperationInput>: Handler {
    
    public typealias Input = SerializeStepInput<OperationInput>
    
    public typealias Output = SdkHttpRequestBuilder
    
    public init() {}
    
    public func handle(context: HttpContext, input: Input) -> Result<SdkHttpRequestBuilder, Error> {
        // since types don't change in input and output here just return the result to kick of the next step
        return .success(input.builder)
    }
}
