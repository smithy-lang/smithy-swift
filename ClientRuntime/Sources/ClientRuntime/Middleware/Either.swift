 // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

/// This type is either set to type A or type B
enum Either<A, B> {
    case left(A)
    case right(B)
}

/// Implement Handler for Either<A,B> when A and B are handlers of the same type
extension Either: Handler where A: Handler, B: Handler, A.TContext == B.TContext, A.TSubject == B.TSubject, A.TError == B.TError {
    func handle(context: A.TContext, result: Result<A.TSubject, A.TError>) -> Result<A.TSubject, A.TError> {
        switch self {
        case .left(let aHandler):
            return aHandler.handle(context: context, result: result)
        case .right(let bHandler):
            return bHandler.handle(context: context, result: result)
        }
    }
}
