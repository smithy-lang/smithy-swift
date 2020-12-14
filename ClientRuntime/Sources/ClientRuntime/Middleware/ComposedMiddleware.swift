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

// used to create middleware from a handler
struct ComposedMiddleware<TContext: Any, TSubject: Any, TError: Error> {
    private var _handle: (TContext, TSubject, AnyHandler<TContext, TSubject, TError>) -> Result<TSubject, TError>
    // the next handler to call
    let handler: AnyHandler<TContext, TSubject, TError>
    public var id: String
    
    public init<H: Handler> (_ handler: H, id: String)
           where  H.TContext == TContext, H.TSubject == TSubject, H.TError == TError {
        
        if let alreadyComposed = handler as? ComposedMiddleware<TContext, TSubject, TError> {
            self = alreadyComposed
            return
        }
        
        self.handler = AnyHandler(handler)
        self.id = id
        self._handle = {context, subject, next in
            next.handle(context: context, subject: subject)
        }
    }
       
}

extension ComposedMiddleware : Middleware {
 
    func handle<H: Handler>(context: TContext, subject: TSubject, next: H) -> Result<TSubject, TError> where H.TContext == TContext,
                                                                                                             H.TError == TError,
                                                                                                             H.TSubject == TSubject {
        _handle(context, subject, handler)
    }
}
