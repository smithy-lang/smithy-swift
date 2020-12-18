// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol Handler {
    associatedtype TSubject
    associatedtype TError: Error
       
    func handle(context: MiddlewareContext, result: Result<TSubject, TError>) -> Result<TSubject, TError>
}

extension Handler {
    func eraseToAnyHandler() -> AnyHandler<TSubject, TError> {
        return AnyHandler(self)
    }
}
