//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import class SmithyHTTPAPI.SdkHttpRequest
import class SmithyHTTPAPI.HttpResponse

public struct NoopHandler<OperationStackOutput>: Handler {
    public init() {}

    public func handle(
        context: Smithy.Context,
        input: SdkHttpRequest
    ) async throws -> OperationOutput<OperationStackOutput> {
        return OperationOutput<OperationStackOutput>(httpResponse: HttpResponse())
    }
}
