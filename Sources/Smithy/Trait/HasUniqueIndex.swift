//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol HasUniqueIndex: Sendable {
    static var uniqueIndex: Int { get }
}

extension HasUniqueIndex {
    var uniqueIndex: Int { Self.uniqueIndex }
}
