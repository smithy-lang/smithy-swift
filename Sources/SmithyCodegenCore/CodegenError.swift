//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An error that is thrown for general code generation problems.
public struct CodegenError: Error {
    public let localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
