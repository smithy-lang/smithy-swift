// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

public protocol Handler {
    associatedtype TContext
    associatedtype TSubject
    associatedtype TError: Error
       
    func handle(context: TContext, result: Result<TSubject, TError>) -> Result<TSubject, TError>
}
