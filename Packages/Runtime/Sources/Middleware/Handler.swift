// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol Handler {
    associatedtype Input
    associatedtype Output
    associatedtype Context: MiddlewareContext
    associatedtype MiddlewareError: Error
       
    func handle(context: Context, input: Input) -> Result<Output, MiddlewareError>
}

extension Handler {
    public func eraseToAnyHandler() -> AnyHandler<Input, Output, Context, MiddlewareError> {
        return AnyHandler(self)
    }
}
