//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/spec/type-refinement-traits.html#enumvalue-trait
public struct EnumValueTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "enumValue") }

    public var node: Node

    public init(node: Node) throws {
        self.node = node
    }

    public init(value: String) {
        self.node = .string(value)
    }

    public init(value: Int) {
        self.node = .number(Double(value))
    }
}
