//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyHTTPAPI.HTTPStatusCode
import struct SmithyRetriesAPI.RetryErrorInfo
import enum SmithyRetriesAPI.RetryErrorType
import protocol SmithyRetriesAPI.RetryErrorInfoProvider
import struct Foundation.TimeInterval

public enum DefaultRetryErrorInfoProvider: RetryErrorInfoProvider, Sendable {
    /// Returns information used to determine how & if to retry an error.
    /// - Parameter error: The error to be triaged for retry info
    /// - Returns: `RetryErrorInfo` for the passed error, or `nil` if the error should not be retried.
    public static func errorInfo(for error: Error) -> RetryErrorInfo? {
        var hint: TimeInterval?
        let retryableStatusCodes: [HTTPStatusCode] = [
            .internalServerError,  // 500
            .badGateway,           // 502
            .serviceUnavailable,   // 503
            .gatewayTimeout,       // 504
        ]
        if let retryAfterString = (error as? HTTPError)?.httpResponse.headers.value(for: "x-retry-after") {
            hint = TimeInterval(retryAfterString)
        }
        if let modeledError = error as? ModeledError {
            let type = type(of: modeledError)
            guard type.isRetryable else { return nil }
            let errorType: RetryErrorType = type.isThrottling ? .throttling : type.fault.retryErrorType
            return .init(errorType: errorType, retryAfterHint: hint, isTimeout: false)
        } else if let code = (error as? HTTPError)?.httpResponse.statusCode, retryableStatusCodes.contains(code) {
            return .init(errorType: .serverError, retryAfterHint: hint, isTimeout: false)
        }
        return nil
    }
}

private extension ErrorFault {

    var retryErrorType: RetryErrorType {
        switch self {
        case .client: return .clientError
        case .server: return .serverError
        }
    }
}
