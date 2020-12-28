// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public struct InitializeStep<Output: HttpResponseBinding>: MiddlewareStack {
    
    public var orderedMiddleware: OrderedGroup<SdkHttpRequest, Output> = OrderedGroup<SdkHttpRequest, Output>()
    
    public var id: String = "InitializeStep"
    
    public typealias MInput = SdkHttpRequest
    
    public typealias MOutput = Output
}
