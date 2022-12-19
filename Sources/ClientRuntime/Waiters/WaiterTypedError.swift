/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

/// An error that may be identified by a string error type, for the purpose of matching the error to a Smithy `errorType` acceptor.
/// This protocol will only be extended onto errors that have a Smithy waiter defined for them, and is only intended for use in the
/// operation of a waiter.
public protocol WaiterTypedError: Error {

    /// The Smithy identifier, without namespace, for the type of this error, or `nil` if the
    /// error has no known type.
    var waiterErrorType: String? { get }
}
