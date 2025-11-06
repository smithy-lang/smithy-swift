//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct InvalidEncodingError: Error {
    public var localizedDescription: String { "The data in the response could not be parsed" }
    public let wrapped: Error // this will be the underlying error thrown by the parser implementation

    public init(wrapped: Error) {
        self.wrapped = wrapped
    }
}
