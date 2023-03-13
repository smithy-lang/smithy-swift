//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

/// A classification that is assigned to an error returned by an operation, for the purpose of
/// determining whether & how the operation should be retried.
///
/// > Note: Based on _The Design and Implementation of the AWS SDKs_ section 3.2.1, The Smithy Retry Interface, `RetryErrorType`.
public enum RetryErrorType {

    /// This is a connection level error such as a socket timeout,
    /// socket connect error, tls negotiation timeout etc...
    /// Typically these should never be applied for non-idempotent,
    /// request types since in this scenario, it’s impossible
    /// to know whether the operation had a side effect on the server.
    case transient

    /// This is an error where the server explicitly told the client
    /// to back off, such as a 429 or 503 HTTP error.
    case throttling

    /// This is a server error that isn’t explicitly throttling but is
    /// considered by the client to be something that should be retried.
    case serverError

    /// Doesn’t count against any budgets.
    /// This could be something like a 401 challenge in HTTP.
    case clientError
}

extension RetryErrorType {
    
    func toCRTType() -> AwsCommonRuntimeKit.RetryError {
        switch self {
        case .transient: return .transient
        case .throttling: return .throttling
        case .serverError: return .serverError
        case .clientError: return .clientError
        }
    }
}
