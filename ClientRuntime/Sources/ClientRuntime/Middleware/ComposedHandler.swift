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

// handler chain, used to decorate a handler with middleware
struct ComposedHandler<TContext: Any, TSubject: Any, TError: Error> {
    // the next handler to call
    let next: AnyHandler<TContext, TSubject, TError>
    
    // the middleware decorating 'next'
    let with: AnyMiddleware<TContext, TSubject, TError>
    
    public init<H: Handler, M: Middleware> (_ realNext: H, _ realWith: M)
           where  H.TContext == TContext, H.TSubject == TSubject, H.TError == TError,
                  M.TContext == TContext, M.TSubject == TSubject, M.TError == TError
    {
        
        if let alreadyComposed = realNext as? ComposedHandler<TContext, TSubject, TError> {
            self = alreadyComposed
            return
        }
        
        self.next = AnyHandler(realNext)
        self.with = AnyMiddleware(realWith)
    }
       
    
}

extension ComposedHandler : Handler {
    func handle(context: TContext, subject: TSubject) -> Result<TSubject, TError> {
        return self.with.handle(context: context, subject: subject, next: self.next)
    }
}
