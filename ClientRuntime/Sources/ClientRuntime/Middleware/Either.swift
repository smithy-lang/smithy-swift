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

/// This type is either set to type A or type B
enum Either<A, B> {
    case Left(A)
    case Right(B)
}

/// Implement Handler for Either<A,B> when A and B are handlers of the same type
extension Either: Handler where A: Handler, B: Handler, A.TContext == B.TContext, A.TSubject == B.TSubject, A.TError == B.TError {
    func handle(context: A.TContext, subject: A.TSubject) -> Result<A.TSubject, A.TError> {
        switch self {
        case .Left(let aHandler):
            return aHandler.handle(context: context, subject: subject)
        case .Right(let bHandler):
            return bHandler.handle(context: context, subject: subject)
        }
    }
}
