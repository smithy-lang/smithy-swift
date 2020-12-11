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

struct HandlerFunctionWrapper<TContext: Any, TSubject: Any, TError: Error> : Handler {
   
    let _handler: HandlerFunction<TContext, TSubject, TError>
    
    init(_ handler: @escaping HandlerFunction<TContext, TSubject, TError>) {
        self._handler = handler
    }

    func handle(context: TContext, subject: TSubject) -> Result<TSubject, TError> {
        return _handler(context, subject)
    }
    
}
