//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public struct MockHandler<Output>: Handler {

    public typealias Context = HttpContext
    public typealias MockHandlerCallback = (Context, SdkHttpRequest) async throws -> OperationOutput<Output>
    let handleCallback: MockHandlerCallback
    public init(handleCallback: @escaping MockHandlerCallback) {
        self.handleCallback = handleCallback
    }

    public func handle(context: Context, input: SdkHttpRequest) async throws -> OperationOutput<Output> {
        return try await self.handleCallback(context, input)
    }

    public typealias Input = SdkHttpRequest

    public typealias Output = OperationOutput<Output>
}
