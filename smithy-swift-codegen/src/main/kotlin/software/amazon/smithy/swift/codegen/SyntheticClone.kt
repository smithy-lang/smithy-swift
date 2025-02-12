/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.AbstractTrait
import software.amazon.smithy.model.traits.AbstractTraitBuilder
import software.amazon.smithy.utils.SmithyBuilder
import software.amazon.smithy.utils.ToSmithyBuilder

/**
 * Defines a shape as being a clone of another modeled shape.
 *
 * Must only be used as a runtime trait-only applied to shapes based on model processing
 */
class SyntheticClone private constructor(
    builder: Builder,
) : AbstractTrait(ID, builder.sourceLocation),
    ToSmithyBuilder<SyntheticClone> {
    val archetype: ShapeId

    override fun createNode(): Node = throw CodegenException("attempted to serialize runtime only trait")

    override fun toBuilder(): SmithyBuilder<SyntheticClone> =
        builder()
            .archetype(archetype)

    /**
     * Builder for [SyntheticClone].
     */
    class Builder : AbstractTraitBuilder<SyntheticClone, Builder>() {
        lateinit var archetype: ShapeId

        override fun build(): SyntheticClone = SyntheticClone(this)

        fun archetype(archetype: ShapeId): Builder {
            this.archetype = archetype
            return this
        }
    }

    companion object {
        val ID = ShapeId.from("smithy.swift.traits#SyntheticClone")
        private const val ARCHETYPE = "archetype"

        /**
         * @return Returns a builder used to create [SyntheticClone].
         */
        fun builder(): Builder = Builder()
    }

    init {
        archetype = requireNotNull(builder.archetype) { "Original ShapeId is required for SyntheticClone trait" }
    }
}
