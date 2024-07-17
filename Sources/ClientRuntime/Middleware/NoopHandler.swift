//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPResponse

public struct NoopHandler<OperationStackOutput>: Handler {
    public init() {}

    public func handle(
        context: Smithy.Context,
        input: HTTPRequest
    ) async throws -> OperationOutput<OperationStackOutput> {
        return OperationOutput<OperationStackOutput>(httpResponse: HTTPResponse())
    }
}
