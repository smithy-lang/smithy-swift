//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public enum RetryError {
    case transient
    case throttling
    case serverError
    case clientError
}

public extension RetryError {
    func toCRTType() -> CRTRetryError {
        switch self {
        case .transient: return .transient
        case .throttling: return .throttling
        case .serverError: return .serverError
        case .clientError: return .clientError
        }
    }
}
