//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

/// Jitter mode for use in determining retry timing.
///
/// For a great writeup on these options see:
/// https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
///
/// > Note: Based on _The Design and Implementation of the AWS SDKs_ section 3.2.1, The Smithy Retry Interface, `ExponentialBackOffJitterType`.
public enum ExponentialBackOffJitterType {

    /// Uses Full
    case `default`

    case none

    case full

    case decorrelated
}

extension ExponentialBackOffJitterType {

    func toCRTType() -> AwsCommonRuntimeKit.ExponentialBackoffJitterMode {
        switch self {
        case .`default`: return .`default`
        case .none: return .none
        case .full: return .full
        case .decorrelated: return .decorrelated
        }
    }
}
