// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public struct InitializeStep<StepInput, StepOutput>: MiddlewareStack {
    
    public var orderedMiddleware: OrderedGroup<StepInput, StepOutput> = OrderedGroup<StepInput, StepOutput>()
    
    public var id: String = "InitializeStep"
    
    public typealias MInput = StepInput
    
    public typealias MOutput = StepOutput
}
