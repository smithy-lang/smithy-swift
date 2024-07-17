//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import ClientRuntime

public struct MockHandler<Output>: Handler {
    public typealias MockHandlerCallback = (Context, HTTPRequest) async throws -> OperationOutput<Output>
    let handleCallback: MockHandlerCallback
    public init(handleCallback: @escaping MockHandlerCallback) {
        self.handleCallback = handleCallback
    }

    public func handle(context: Context, input: HTTPRequest) async throws -> OperationOutput<Output> {
        return try await self.handleCallback(context, input)
    }

    public typealias Input = HTTPRequest
    public typealias Output = OperationOutput<Output>
}
