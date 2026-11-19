//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Thrown when a schema does not have the structure that an operation on it requires.
public struct SchemaError: Error {
    public let localizedDescription: String

    public init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
