//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyRetriesAPI.RetryErrorType
import AwsCommonRuntimeKit

public extension RetryErrorType {

    func toCRTType() -> AwsCommonRuntimeKit.RetryError {
        switch self {
        case .transient: return .transient
        case .throttling: return .throttling
        case .serverError: return .serverError
        case .clientError: return .clientError
        }
    }
}
