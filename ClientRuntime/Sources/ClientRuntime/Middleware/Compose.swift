// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Compose (wrap) the handler with the given middleware
func compose<TContext: Any, TSubject: Any, TError, H: Handler, M: Middleware> (
    handler: H,
    with: M...
) -> some Handler
    where M.TContext == TContext, M.TSubject == TSubject, M.TError == TError,
    H.TContext == TContext, H.TSubject == TSubject, H.TError == TError {
    if with.isEmpty {
        return Either<H, ComposedHandler<TContext, TSubject, TError>>.left(handler)
    }
    
    let cnt = with.count
    var h = ComposedHandler<TContext, TSubject, TError>(handler, with[cnt - 1])
    for i in stride(from: cnt - 2, through: 0, by: -1) {
        h = ComposedHandler(h, with[i])
    }
    
    return Either<H, ComposedHandler<TContext, TSubject, TError>>.right(h)
}
