//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum DefaultRetryErrorInfoProvider: RetryErrorInfoProvider {

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
        } else {
            return .init(errorType: .serverError, retryAfterHint: hint, isTimeout: false)
        }
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
