//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SmithyTestUtilError: Error {
    public var localizedDescription: String

    public init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
