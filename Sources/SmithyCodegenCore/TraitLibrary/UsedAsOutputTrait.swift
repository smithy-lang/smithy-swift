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
import var Smithy.traitUniqueIndexCounter

@_spi(SchemaBasedSerde)
public final class UsedAsOutputTrait: Trait {
    public static var id: ShapeID { .init("swift.synthetic", "usedAsOutput") }

    public static let uniqueIndex = traitUniqueIndexCounter.getNextIndex()

    public var node: Node { [:] }

    public init(node: Node) throws {}

    public init() {}
}
