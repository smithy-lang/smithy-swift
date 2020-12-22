// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol Handler {
    associatedtype Input
    associatedtype Output
       
    func handle(context: MiddlewareContext, result: Result<Input, Error>) -> Result<Output, Error>
}

extension Handler {
    func eraseToAnyHandler() -> AnyHandler<Input, Output> {
        return AnyHandler(self)
    }
}
