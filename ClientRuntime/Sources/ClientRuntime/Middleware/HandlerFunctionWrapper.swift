 // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

struct HandlerFunctionWrapper<TContext: Any, TSubject: Any, TError: Error> : Handler {
    let _handler: HandlerFunction<TContext, TSubject, TError>
    
    init(_ handler: @escaping HandlerFunction<TContext, TSubject, TError>) {
        self._handler = handler
    }
    
    func handle(context: TContext, result: Result<TSubject, TError>) -> Result<TSubject, TError> {
        return _handler(context, result)
    }
    
}
