/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.struct

import software.amazon.smithy.aws.traits.customizations.S3UnwrappedXmlOutputTrait
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.member.MemberShapeDecodeGenerator
import software.amazon.smithy.swift.codegen.model.ShapeMetadata
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes

open class StructDecodeGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val members: List<MemberShape>,
    private val metadata: Map<ShapeMetadata, Any>,
    private val writer: SwiftWriter,
) : MemberShapeDecodeGenerator(ctx, writer, shapeContainingMembers) {

    fun render() {
        val symbol = ctx.symbolProvider.toSymbol(shapeContainingMembers)
        writer.openBlock(
            "static func read(from reader: \$N) throws -> \$N {", "}",
            ctx.service.readerSymbol,
            symbol,
        ) {
            // S3:SelectObjectContent's event stream output contains EndEvent, which has empty payload.
            // The additional condition here allows returning new instance of a struct even if value isn't found in reader
            //   as long as the struct has no properties.
            val additionalCondition = "|| Mirror(reflecting: self).children.isEmpty ".takeIf {
                ctx.settings.sdkId == "S3" && members.isEmpty()
            } ?: ""
            writer.write(
                "guard reader.hasContent \$Lelse { throw \$N.requiredValueNotPresent }",
                additionalCondition,
                SmithyReadWriteTypes.ReaderError,
            )
            if (members.isEmpty()) {
                writer.write("return \$N()", symbol)
            } else {
                writer.write("var value = \$N()", symbol)
                if (isUnwrapped) {
                    writer.write("let reader = reader.parent ?? reader")
                }
                members.forEach { render(it) }
                writer.write("return value")
            }
        }
    }

    private val isUnwrapped: Boolean =
        (metadata[ShapeMetadata.OPERATION_SHAPE] as? OperationShape)?.hasTrait<S3UnwrappedXmlOutputTrait>() ?: false
}
