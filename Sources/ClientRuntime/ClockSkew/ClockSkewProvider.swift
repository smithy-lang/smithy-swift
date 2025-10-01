//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.TimeInterval

/// A closure that is called to determine what, if any, correction should be made to the system's clock when signing requests.
///
/// Returns: a `TimeInterval` that represents the correction ("clock skew") that should be applied to the system clock,
/// or `nil` if no correction should be applied.
/// - Parameters:
///   - request: The request that was sent to the server. (Typically this is a `HTTPRequest`)
///   - response: The response that was returned from the server. (Typically this is a `HTTPResponse`)
///   - error: The error that was returned by the server; typically this is a `ServiceError` with an error code that
///   indicates clock skew is or might be the cause of the failed request.
/// - Returns: The calculated clock skew `TimeInterval`, or `nil` if no clock skew adjustment is to be applied.

public typealias ClockSkewProvider<Request, Response> = @Sendable (Request, Response, Error) -> TimeInterval?
