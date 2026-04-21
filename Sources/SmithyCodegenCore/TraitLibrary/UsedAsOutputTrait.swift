//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import protocol Smithy.Trait

@_spi(SchemaBasedSerde)
public struct UsedAsOutputTrait: Trait {
    public static var id: ShapeID { .init("swift.synthetic", "usedAsOutput") }

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
