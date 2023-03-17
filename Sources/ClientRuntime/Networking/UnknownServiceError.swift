/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// General networking protocol independent service error structure used when exact error
/// could not be deduced during deserialization
public struct UnknownServiceError: ServiceError, Equatable {
    public var _retryable: Bool = false
    public var _isThrottling: Bool = false
    public var _type: ErrorType = .unknown
    public var _message: String?
    public var _errorType: String?
    public var _smithyErrorTypeName: String? { nil }
}

extension UnknownServiceError {
    public init(errorType: String? = nil, message: String? = nil) {
        self._errorType = errorType
        self._message = message
    }
}
