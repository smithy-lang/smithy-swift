//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

/// A `Sendable` wrapper for `HttpInterceptorProvider` that enables safe concurrent access.
///
/// This wrapper allows non-`Sendable` HTTP interceptor providers to be stored in `Sendable` contexts
/// by boxing them and forwarding method calls.
///
/// Note: Uses `@unchecked Sendable` because the wrapper is designed to safely encapsulate
/// non-Sendable providers for use in concurrent contexts. The safety is ensured by the
/// immutability of the stored provider reference.
public struct SendableHttpInterceptorProviderBox: HttpInterceptorProvider, @unchecked Sendable {
    internal let _provider: any HttpInterceptorProvider

    public init(_ provider: any HttpInterceptorProvider) {
        self._provider = provider
    }

    public func create<InputType, OutputType>() -> any Interceptor<InputType, OutputType, HTTPRequest, HTTPResponse> {
        return _provider.create()
    }
}
