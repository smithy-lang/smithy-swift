//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum DefaultRetryErrorInfoProvider: RetryErrorInfoProvider {

    public static func errorInfo(for error: Error) -> RetryErrorInfo? {
        // TODO: Fill me in
        return RetryErrorInfo(errorType: .serverError, retryAfterHint: nil, isTimeout: false)
    }
}
