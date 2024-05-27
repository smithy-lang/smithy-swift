//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

/// type erase the Middleware protocol
public struct AnyMiddleware<MInput, MOutput>: Middleware {

    private let _handle: (Context, MInput, AnyHandler<MInput, MOutput>) async throws -> MOutput

    public var id: String

    public init<M: Middleware>(_ realMiddleware: M)
    where M.MInput == MInput, M.MOutput == MOutput {
        if let alreadyErased = realMiddleware as? AnyMiddleware<MInput, MOutput> {
            self = alreadyErased
            return
        }

        self.id = realMiddleware.id
        self._handle = realMiddleware.handle
    }

    public init<H: Handler>(handler: H, id: String) where H.Input == MInput,
                                                          H.Output == MOutput {

        self._handle = { context, input, handler in
            try await handler.handle(context: context, input: input)
        }
        self.id = id
    }

    public func handle<H: Handler>(context: Context, input: MInput, next: H) async throws -> MOutput
    where H.Input == MInput,
          H.Output == MOutput {
        return try await _handle(context, input, next.eraseToAnyHandler())
    }
}
