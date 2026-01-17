//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DeprecatedTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "deprecated") }

    public let node: Node
    public let since: String?

    public init(node: Node) throws {
        guard case .object(let object) = node else {
            throw TraitError("DeprecatedTrait does not have root object")
        }
        self.since = object["since"]?.string
        self.node = node
    }
}
