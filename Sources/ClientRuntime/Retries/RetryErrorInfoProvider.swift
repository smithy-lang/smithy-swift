//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A type that can triage errors for determining how & if to retry the error.
///
/// Based on the error's content & properties, the retry error info provider will determine the general retry type of this error
/// and attempt to establish a "retry hint" delay suggesting when to retry the error if such a hint is available.  If the error
/// should not be retried, the retry error info will be `nil`.
///
/// `smithy-swift` will provide a default error info provider, but services may customize their triage of errors by
/// providing their own implementation.
public protocol RetryErrorInfoProvider {

    /// Returns information used to determine how & if to retry an error.
    /// - Parameter error: The error to be triaged for retry info
    /// - Returns: `RetryErrorInfo` for the passed error, or `nil` if the error should not be retried.
    static func errorInfo(for error: Error) async -> RetryErrorInfo?
}
