//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public enum ExponentialBackOffJitterType : Sendable {
    case `default`
    case none
    case full
    case decorrelated
}

extension ExponentialBackOffJitterType {

    func toCRTType() -> AwsCommonRuntimeKit.ExponentialBackoffJitterMode {
        switch self {
        case .default: return .default
        case .none: return .none
        case .full: return .full
        case .decorrelated: return .decorrelated
        }
    }
}
