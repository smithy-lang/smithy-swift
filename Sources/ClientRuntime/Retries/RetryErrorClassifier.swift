//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

public protocol RetryErrorClassifying {
    associatedtype ServiceErrorWrapper: ServiceErrorProviding

    func retryErrorInfo(error: SdkError<ServiceErrorWrapper>) -> RetryErrorInfo?
}

/// Returns `ErrorInfo` for the passed error, expressing the error's
public struct RetryErrorClassifier<T: ServiceErrorProviding>: RetryErrorClassifying {

    public typealias ServiceErrorWrapper = T

    public init() {}

    public func retryErrorInfo(error: SdkError<T>) -> RetryErrorInfo? {
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
