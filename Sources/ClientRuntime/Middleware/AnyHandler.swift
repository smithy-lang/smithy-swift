//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

/// Type erased Handler
public struct AnyHandler<MInput, MOutput>: Handler {
    private let _handle: (Context, MInput) async throws -> MOutput

    public init<H: Handler> (_ realHandler: H)
    where H.Input == MInput, H.Output == MOutput {
        if let alreadyErased = realHandler as? AnyHandler<MInput, MOutput> {
            self = alreadyErased
            return
        }
        self._handle = realHandler.handle
    }

    public func handle(context: Context, input: MInput) async throws -> MOutput {
        return try await _handle(context, input)
    }
}
