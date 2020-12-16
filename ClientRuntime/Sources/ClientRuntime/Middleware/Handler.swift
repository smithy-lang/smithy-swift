// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public protocol Handler {
    associatedtype Input
    associatedtype Output
    associatedtype Context: MiddlewareContext
       
    func handle(context: Context, input: Input) -> Result<Output, Error>
}

extension Handler {
    func eraseToAnyHandler() -> AnyHandler<Input, Output, Context> {
        return AnyHandler(self)
    }
}
