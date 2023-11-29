//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct NoopHandler<Output>: Handler {
    public init() {}

    public func handle(context: HttpContext, input: SdkHttpRequest) async throws -> OperationOutput<Output> {
        return OperationOutput<Output>(httpResponse: HttpResponse())
    }
}
