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

/// Compose (wrap) the handler with the given middleware
func compose<TContext: Any, TSubject: Any, TError, H:Handler, M: Middleware> (
    handler: H,
    with: M...
) -> some Handler
    where M.TContext == TContext, M.TSubject == TSubject, M.TError == TError,
    H.TContext == TContext, H.TSubject == TSubject, H.TError == TError
{
    if (with.isEmpty) {
        return Either<H, ComposedHandler<TContext, TSubject, TError>>.Left(handler)
    }
    
    let cnt = with.count
    var h = ComposedHandler<TContext, TSubject, TError>(handler, with[cnt - 1])
    for i in stride(from: cnt - 2, through: 0, by: -1){
        h = ComposedHandler(h, with[i])
    }
    
    return Either<H, ComposedHandler<TContext, TSubject, TError>>.Right(h)
}
