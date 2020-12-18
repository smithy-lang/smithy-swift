// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

struct HandlerFunctionWrapper<TSubject: Any, TError: Error>: Handler {
    let _handler: HandlerFunction<TSubject, TError>
    
    init(_ handler: @escaping HandlerFunction<TSubject, TError>) {
        self._handler = handler
    }
    
    func handle(context: MiddlewareContext, result: Result<TSubject, TError>) -> Result<TSubject, TError> {
        return _handler(context, result)
    }
}
