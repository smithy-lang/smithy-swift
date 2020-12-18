// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Reacts to the handler's response returned by the recipient of the request
/// message. Deserializes the response into a structured type or error above
/// stacks can react to.
///
/// Should only forward Request to underlying handler.
///
/// Takes Request, and returns result or error.
///
/// Receives raw response, or error from underlying handler.
public struct DeserializeStep<TSubject, TError: Error>: MiddlewareStack {
 
    public var orderedMiddleware: OrderedGroup<TSubject, TError>
    
    public var id: String = "DeserializeStep"
    
    public typealias TSubject = TSubject
    
    public typealias TError = TError
}
