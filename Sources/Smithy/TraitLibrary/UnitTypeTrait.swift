//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
public struct UnitTypeTrait: Trait {
    public static var id: ShapeID { .init("smithy.api", "Unit") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
