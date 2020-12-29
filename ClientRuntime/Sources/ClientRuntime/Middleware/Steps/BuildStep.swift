// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Adds additional metadata to the serialized transport message,
/// (e.g. HTTP's Content-Length header, or body checksum). Decorations and
/// modifications to the message should be copied to all message attempts.
///
/// Takes Request, and returns result or error.
///
/// Receives result or error from Finalize step.
public struct BuildStep: MiddlewareStack {
    
    public typealias Context = HttpContext
    

    public var orderedMiddleware: OrderedGroup<SdkHttpRequestBuilder, SdkHttpRequestBuilder, HttpContext> = OrderedGroup<SdkHttpRequestBuilder, SdkHttpRequestBuilder, HttpContext>()
    
    public var id: String = "BuildStep"
    
    public typealias MInput = SdkHttpRequestBuilder
    
    public typealias MOutput = SdkHttpRequestBuilder
}

public struct BuildStepHandler: Handler {
    
    public typealias Input = SdkHttpRequestBuilder
    
    public typealias Output = SdkHttpRequestBuilder
    
    public func handle(context: HttpContext, input: Input) -> Result<SdkHttpRequestBuilder, Error> {
        // since types don't change in input and output here just return the result to kick of the next step
        return .success(input)
    }
}
