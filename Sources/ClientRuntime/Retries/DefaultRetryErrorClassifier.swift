//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

/// Returns retry error info for the passed error, or `nil` if the error is not retryable.
public struct DefaultRetryErrorClassifier: RetryErrorClassifier {

    public init() {}

    /// Analyzes the error resulting from an operation and returns `RetryErrorInfo` if the error is retryable, `nil` otherwise.
    /// - Parameter error: The operation error to be examined.
    /// - Returns: `RetryErrorInfo` describing the retryability of this error, or `nil` if the error is not retryable.
    public func retryErrorInfo<T: ServiceErrorProviding>(error: SdkError<T>) -> RetryErrorInfo? {
        switch error {
        case .service(let serviceErrorProvider, let httpResponse):
            guard let errorType = process(serviceError: serviceErrorProvider.serviceError) else { return nil }
            let hint = process(httpResponse: httpResponse)
            return RetryErrorInfo(errorType: errorType, retryAfterHint: hint)
        case .client(let error, let httpResponse):
            guard let errorType = process(error: error) else { return nil }
            let hint = process(httpResponse: httpResponse)
            return RetryErrorInfo(errorType: errorType, retryAfterHint: hint)
        case .unknown(let error):
            guard let error = error else { return nil }
            guard let errorType = process(error: error) else { return nil }
            return RetryErrorInfo(errorType: errorType, retryAfterHint: nil)
        }
    }

        // MARK: - Private methods

    private func process(serviceError: ServiceError) -> RetryErrorType? {
        // TODO: fill in & test
        if serviceError._isThrottling {
            return .throttling
        } else if serviceError._retryable {
            return .transient
        }
        return nil
    }

    private func process(error: Error) -> RetryErrorType? {
        // TODO: fill in & test
        return nil
    }

    private func process(httpResponse: HttpResponse?) -> TimeInterval? {
        guard let retryAfter = httpResponse?.headers.value(for: "x-amz-retry-after") else { return nil }
        guard let hint = TimeInterval(retryAfter) else { return nil }
        return hint
    }
}
