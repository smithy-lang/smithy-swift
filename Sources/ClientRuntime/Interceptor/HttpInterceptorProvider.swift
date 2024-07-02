//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Provides implementations of `HttpInterceptor`.
///
/// For the generic counterpart, see `InterceptorProvider`.
public protocol HttpInterceptorProvider {

    /// Creates an instance of an `HttpInterceptor` implementation.
    ///
    /// - Returns: The `HttpInterceptor` implementation.
    func create<InputType, OutputType>() -> any HttpInterceptor<InputType, OutputType>
}
