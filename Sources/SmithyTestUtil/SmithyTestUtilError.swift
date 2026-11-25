//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An error thrown by the test harness itself, as opposed to by the code under test.
public struct SmithyTestUtilError: Error, CustomStringConvertible {
    public var localizedDescription: String

    public init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }

    public var description: String { localizedDescription }
}
