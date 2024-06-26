//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

// handler chain, used to decorate a handler with middleware
public struct ComposedHandler<MInput, MOutput> {
    // the next handler to call
    let next: AnyHandler<MInput, MOutput>

    // the middleware decorating 'next'
    let with: AnyMiddleware<MInput, MOutput>

    public init<H: Handler, M: Middleware> (_ realNext: H, _ realWith: M)
    where H.Input == MInput,
          H.Output == MOutput,
          M.MInput == MInput,
          M.MOutput == MOutput {

        self.next = AnyHandler(realNext)
        self.with = AnyMiddleware(realWith)
    }
}

extension ComposedHandler: Handler {
    public func handle(context: Context, input: MInput) async throws -> MOutput {
        return try await with.handle(context: context, input: input, next: next)
    }
}
