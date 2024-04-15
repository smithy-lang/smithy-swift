/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.SmithyFormURLTypes
import software.amazon.smithy.swift.codegen.SmithyJSONTypes
import software.amazon.smithy.swift.codegen.SmithyXMLTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.WireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.addImports
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.requestWireProtocol
import software.amazon.smithy.swift.codegen.integration.serde.readwrite.responseWireProtocol
import software.amazon.smithy.swift.codegen.model.ShapeMetadata
import software.amazon.smithy.swift.codegen.model.isError
import java.lang.Exception

class StructEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val shapeContainingMembers: Shape,
    private val members: List<MemberShape>,
    private val metadata: Map<ShapeMetadata, Any>,
    private val writer: SwiftWriter
) : MemberShapeEncodeXMLGenerator(ctx, writer) {

    override fun render() {
        writer.addImports(ctx.service.requestWireProtocol)
        val structSymbol = ctx.symbolProvider.toSymbol(shapeContainingMembers)
        writer.openBlock(
            "static func write(value: \$N?, to writer: \$N) throws {", "}",
            structSymbol,
            ctx.service.writerSymbol,
        ) {
            writer.write(
                "guard \$L else { return }",
                "value != nil".takeIf { members.isEmpty() } ?: "let value"
            )
            if (members.isEmpty()) {
                writer.write("_ = writer[\"\"]  // create an empty structure")
            }
            val isErrorMember = shapeContainingMembers.isError
            members.sortedBy { it.memberName }.forEach { writeMember(it, false, isErrorMember) }
            writeExtraMembers()
        }
    }

    private fun writeExtraMembers() {
        when (ctx.service.requestWireProtocol) {
            WireProtocol.FORM_URL -> {
                if (metadata.containsKey(ShapeMetadata.OPERATION_SHAPE) && metadata.containsKey(ShapeMetadata.SERVICE_VERSION)) {
                    val operationShape = metadata[ShapeMetadata.OPERATION_SHAPE] as OperationShape
                    val version = metadata[ShapeMetadata.SERVICE_VERSION] as String
                    writer.write("try writer[\"Action\"].write(\$S)", operationShape.id.name)
                    writer.write("try writer[\"Version\"].write(\$S)", version)
                }
            }
            else -> listOf<MemberShape>()
        }
    }
}

val ServiceShape.writerSymbol: Symbol
    get() = when (requestWireProtocol) {
        WireProtocol.XML -> SmithyXMLTypes.Writer
        WireProtocol.JSON -> SmithyJSONTypes.Writer
        WireProtocol.FORM_URL -> SmithyFormURLTypes.Writer
    }

val ServiceShape.readerSymbol: Symbol
    get() = when (responseWireProtocol) {
        WireProtocol.XML -> SmithyXMLTypes.Reader
        WireProtocol.JSON -> SmithyJSONTypes.Reader
        WireProtocol.FORM_URL -> throw Exception("Reading from Form URL data not supported")
    }
