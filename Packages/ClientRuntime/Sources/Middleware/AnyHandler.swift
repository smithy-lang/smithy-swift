// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Type erased Handler
public struct AnyHandler<MInput, MOutput, Context: MiddlewareContext>: Handler {
    private let _handle: (Context, MInput) async throws -> MOutput
    
    public init<H: Handler> (_ realHandler: H)
    where H.Input == MInput, H.Output == MOutput, H.Context == Context{
        if let alreadyErased = realHandler as? AnyHandler<MInput, MOutput, Context> {
            self = alreadyErased
            return
        }
        self._handle = realHandler.handle
    }
    
    public func handle(context: Context, input: MInput) async throws -> MOutput {
        return try await _handle(context, input)
    }
}
