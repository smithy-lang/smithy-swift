// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Adds additional metadata to the serialized transport message,
/// (e.g. HTTP's Content-Length header, or body checksum). Decorations and
/// modifications to the message should be copied to all message attempts.
///
/// Takes Request, and returns result or error.
///
/// Receives result or error from Finalize step.
public struct BuildStep<TSubject, TError: Error>: MiddlewareStack {

    public var orderedMiddleware: OrderedGroup<TSubject, TError>
    
    public var id: String = "BuildStep"
    
    public typealias TSubject = TSubject
    
    public typealias TError = TError
}
