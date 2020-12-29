// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

struct WrappedHandler<MInput, MOutput, Context: MiddlewareContext>: Handler {
    let _handler: HandlerFunction<MInput, MOutput, Context>
    
    init(_ handler: @escaping HandlerFunction<MInput, MOutput, Context>) {
        self._handler = handler
    }
    
    func handle(context: Context, input: MInput) -> Result<MOutput, Error> {
        return _handler(context, input)
    }
}
