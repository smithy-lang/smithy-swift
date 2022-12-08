/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

/// An error that may be identified by a string error code.
/// The error code identifies the general cause or nature of a server error.
/// Typically this error code will come from a response to a network request.
public protocol CodedError: Error {

    /// The code that identifies the cause of this error, or `nil` if the
    /// error has no known code.
    var errorCode: String? { get }
}
