//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context

public protocol Handler {
    associatedtype Input
    associatedtype Output

    func handle(context: Context, input: Input) async throws -> Output
}

extension Handler {
    public func eraseToAnyHandler() -> AnyHandler<Input, Output> {
        return AnyHandler(self)
    }
}
