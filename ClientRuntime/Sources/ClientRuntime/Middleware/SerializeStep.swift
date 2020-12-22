// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Serializes the prepared input into a data structure that can be consumed
/// by the target transport's message, (e.g. REST-JSON serialization)
///
/// Converts Input Parameters into a Request, and returns the result or error.
///
/// Receives result or error from Build step.
public struct SerializeStep<StepInput, StepOutput>: MiddlewareStack {
    
    public var orderedMiddleware: OrderedGroup<StepInput, StepOutput> = OrderedGroup<StepInput, StepOutput>()
    
    public var id: String = "SerializeStep"
    
    public typealias MInput = StepInput
    
    public typealias MOutput = StepOutput
}
