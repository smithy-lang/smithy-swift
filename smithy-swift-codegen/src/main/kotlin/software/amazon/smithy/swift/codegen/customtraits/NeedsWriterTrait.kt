/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.customtraits

import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.Trait

class NeedsWriterTrait : Trait {
    @Suppress("ktlint:standard:property-naming")
    val ID = ShapeId.from("software.amazon.smithy.swift.codegen.synthetic#NeedsWriter")

    override fun toNode(): Node = Node.objectNode()

    override fun toShapeId(): ShapeId = ID
}
