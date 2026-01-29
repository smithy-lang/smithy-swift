//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

/// Provides implementations of `HttpInterceptor`.
///
/// For the generic counterpart, see `InterceptorProvider`.
public protocol HttpInterceptorProvider {

    /// Creates an instance of an `HttpInterceptor` implementation.
    ///
    /// - Returns: The `HttpInterceptor` implementation.
    func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse>
}
