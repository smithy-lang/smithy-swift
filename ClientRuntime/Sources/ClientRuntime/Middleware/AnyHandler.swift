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

/// Type erased Handler
public struct AnyHandler<TContext, TSubject, TError: Error> : Handler {
    private let _handle: (TContext, TSubject) -> Result<TSubject, TError>
    
    public init<H: Handler> (_ realHandler: H)
        where  H.TContext == TContext, H.TSubject == TSubject, H.TError == TError
    {
        if let alreadyErased = realHandler as? AnyHandler<TContext, TSubject, TError> {
            self = alreadyErased
            return
        }
        self._handle = realHandler.handle
    }
    
    public func handle(context: TContext, subject: TSubject) -> Result<TSubject, TError> {
        return _handle(context, subject)
    }
}
