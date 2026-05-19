//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Used to raise errors while reading or processing the JSON AST file.
public struct ASTError: Error {
    public let localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
