//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct DefaultTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "default") }

    public let node: Node

    public init(node: Node) throws {
        self.node = node
    }
}
