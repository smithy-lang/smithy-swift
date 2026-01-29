//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.RequestMessage
import protocol Smithy.ResponseMessage

/// A `Sendable` wrapper for `InterceptorProvider` that enables safe concurrent access.
///
/// This wrapper allows non-`Sendable` interceptor providers to be stored in `Sendable` contexts
/// by boxing them and forwarding method calls.
public struct SendableInterceptorProviderBox: InterceptorProvider, Sendable {
    internal let _provider: any InterceptorProvider

    public init(_ provider: any InterceptorProvider) {
        self._provider = provider
    }

    public func create<
        InputType,
        OutputType,
        RequestType: RequestMessage,
        ResponseType: ResponseMessage
    >() -> any Interceptor<InputType, OutputType, RequestType, ResponseType> {
        return _provider.create()
    }
}
