//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// https://smithy.io/2.0/spec/protocol-traits.html#jsonname-trait

@_spi(SchemaBasedSerde)
public struct JSONNameTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "jsonName") }

    public static let uniqueIndex = TraitRegistry.shared.register(Self.self)

    public var node: Node { .string(name) }
    public var name: String

    public init(node: Node) throws {
        guard let name = node.string else { throw TraitError("jsonName trait node must contain String") }
        self.name = name
    }
}
