// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import protocol SmithyAPI.MiddlewareContext

/// used to wrap a handler function as a handler
struct WrappedHandler<MInput, MOutput, Context: MiddlewareContext, MError: Error>: Handler {
    let _handler: HandlerFunction<MInput, MOutput, Context, MError>

    init(_ handler: @escaping HandlerFunction<MInput, MOutput, Context, MError>) {
        self._handler = handler
    }

    func handle(context: Context, input: MInput) -> Result<MOutput, MError> {
        return _handler(context, input)
    }
}
