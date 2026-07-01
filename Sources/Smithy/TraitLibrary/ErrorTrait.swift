//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// https://smithy.io/2.0/spec/type-refinement-traits.html#error-trait
@_spi(SchemaBasedSerde)
public struct ErrorTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "error") }

    public static let uniqueIndex = TraitRegistry.shared.register(Self.self)

    public var node: Node { [:] }

    public init(node: Node) throws {}
}
