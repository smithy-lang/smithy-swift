//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Describes a type that returns retry error info for the passed operation error, or `nil` if the error is not retryable.
public protocol RetryErrorClassifying {

    /// Analyzes the error resulting from an operation and returns `RetryErrorInfo` if the error is retryable, `nil` otherwise.
    /// - Parameter error: The operation error to be examined.
    /// - Returns: `RetryErrorInfo` describing the retryability of this error, or `nil` if the error is not retryable.
    func retryErrorInfo<T: ServiceErrorProviding>(error: SdkError<T>) -> RetryErrorInfo?
}
