/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public protocol ServiceError: RetryableError {
    var _errorType: String? { get }
//    var _type: ErrorType { get set }
//    var _message: String? { get set }
}

//public enum ErrorType: Equatable {
//    case server
//    case client
//    case unknown
//}
public protocol RetryableError {
    var _retryable: Bool { get set }
    var _isThrottling: Bool { get set }
}
