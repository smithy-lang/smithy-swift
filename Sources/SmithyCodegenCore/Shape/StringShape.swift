//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
import enum Smithy.ShapeType
@_spi(SchemaBasedSerde)
import struct Smithy.TraitCollection

/// A ``Shape`` subclass specialized for Smithy strings.
class StringShape: Shape {

    public init(id: ShapeID, traits: TraitCollection) {
        super.init(id: id, type: .string, traits: traits)
    }
}
