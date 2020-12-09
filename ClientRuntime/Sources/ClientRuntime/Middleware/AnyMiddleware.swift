//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

/// type erase the Middleware protocol
public struct AnyMiddleware<TContext, TSubject, TError: Error> : Middleware {
    private let _handle: (TContext, TSubject, AnyHandler<TContext, TSubject, TError>) -> Result<TSubject, TError>

    public var id: String

    public init<M: Middleware>(_ realMiddleware: M)
        where M.TContext == TContext, M.TSubject == TSubject, M.TError == TError {
        if let alreadyErased = realMiddleware as? AnyMiddleware<TContext, TSubject, TError> {
            self = alreadyErased
            return
        }

        self.id = realMiddleware.id
        self._handle = realMiddleware.handle
    }

    public func handle<H>(context: TContext, subject: TSubject, next: H) -> Result<TSubject, TError>
        where H : Handler, H.TContext == TContext, H.TSubject == TSubject, H.TError == TError
    {
        return _handle(context, subject, AnyHandler(next));
    }
    
}
