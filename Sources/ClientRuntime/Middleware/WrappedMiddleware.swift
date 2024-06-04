// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context

/// used to create middleware from a middleware function
struct WrappedMiddleware<MInput, MOutput>: Middleware {
    let _middleware: MiddlewareFunction<MInput, MOutput>
    var id: String

    init(_ middleware: @escaping MiddlewareFunction<MInput, MOutput>, id: String) {
        self._middleware = middleware
        self.id = id
    }

    func handle<H: Handler>(context: Context,
                            input: MInput,
                            next: H) async throws -> MOutput where H.Input == MInput, H.Output == MOutput {
        return try await _middleware(context, input, next.eraseToAnyHandler())
    }
}
