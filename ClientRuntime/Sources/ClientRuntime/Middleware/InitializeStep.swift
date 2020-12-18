// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Initialize Prepares the input, and sets any default parameters as
/// needed, (e.g. idempotency token, and presigned URLs).
///
/// Takes Input Parameters, and returns result or error.
///
/// Receives result or error from Serialize step.
public struct InitializeStep<TSubject, TError:Error>: MiddlewareStack {
    
    public var orderedMiddleware: OrderedGroup<TSubject, TError> = OrderedGroup<TSubject, TError>()
    
    public var id: String = "InitializeStep"
    
    public typealias TSubject = TSubject
    
    public typealias TError = TError
}
