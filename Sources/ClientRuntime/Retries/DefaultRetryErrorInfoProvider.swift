//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

public enum DefaultRetryErrorInfoProvider: RetryErrorInfoProvider {

    static let retryableStatusCodes: [HttpStatusCode] = [
        .internalServerError,  // 500
        .badGateway,           // 502
        .serviceUnavailable,   // 503
        .gatewayTimeout,       // 504
    ]

    public static func errorInfo(for error: Error) -> RetryErrorInfo? {
        var hint: TimeInterval?
        if let retryAfterString = (error as? HTTPError)?.httpResponse.headers.value(for: "x-retry-after") {
            hint = TimeInterval(retryAfterString)
        }
        if let modeledError = error as? ModeledError {
            switch type(of: modeledError).isThrottling {
            case true:
                return .init(errorType: .throttling, retryAfterHint: hint, isTimeout: false)
            case false:
                let errorType = type(of: modeledError).fault.retryErrorType
                return .init(errorType: errorType, retryAfterHint: hint, isTimeout: false)
            }
        } else if let httpError = error as? HTTPError {
            if retryableStatusCodes.contains(httpError.httpResponse.statusCode) {
                return .init(errorType: .serverError, retryAfterHint: hint, isTimeout: false)
            }
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
