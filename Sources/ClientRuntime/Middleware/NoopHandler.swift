//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct NoopHandler<OperationStackOutput>: Handler {
    public init() {}

    public func handle(
        context: HttpContext,
        input: SdkHttpRequest
    ) async throws -> OperationOutput<OperationStackOutput> {
        return OperationOutput<OperationStackOutput>(httpResponse: HttpResponse())
    }
}
