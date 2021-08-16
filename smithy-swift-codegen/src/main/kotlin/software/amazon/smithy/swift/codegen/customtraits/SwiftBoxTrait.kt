/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.customtraits

import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.Trait

class SwiftBoxTrait : Trait {
    val ID = ShapeId.from("software.amazon.smithy.swift.codegen.swift.synthetic#box")
    override fun toNode(): Node = Node.objectNode()

    override fun toShapeId(): ShapeId = ID
}
