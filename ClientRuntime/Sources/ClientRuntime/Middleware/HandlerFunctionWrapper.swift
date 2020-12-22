// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

struct HandlerFunctionWrapper<MInput: Any, MOutput>: Handler {
    let _handler: HandlerFunction<MInput, MOutput>
    
    init(_ handler: @escaping HandlerFunction<MInput, MOutput>) {
        self._handler = handler
    }
    
    func handle(context: MiddlewareContext, result: Result<MInput, Error>) -> Result<MOutput, Error> {
        return _handler(context, result)
    }
}
