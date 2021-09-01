/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.aws.traits.customizations.S3UnwrappedXmlOutputTrait
import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.ShapeMetadata
import software.amazon.smithy.swift.codegen.model.hasTrait

open class StructDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val members: List<MemberShape>,
    private val metadata: Map<ShapeMetadata, Any>,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeXMLGenerator(ctx, writer, defaultTimestampFormat) {

    override fun render() {
        writer.openBlock("public init (from decoder: \$N) throws {", "}", SwiftTypes.Decoder) {
            if (members.isNotEmpty()) {
                renderDecodeBody()
            }
        }
    }

    private fun renderDecodeBody() {
        val containerName = "containerValues"
        var unkeyed = false
        if (responseBodyIsNotWrapped()) {
            writer.write("var $containerName = try decoder.unkeyedContainer()")
            unkeyed = true
        } else {
            writer.write("let $containerName = try decoder.container(keyedBy: CodingKeys.self)")
        }
        members.forEach { member ->
            renderSingleMember(member, containerName, unkeyed)
        }
    }
    private fun responseBodyIsNotWrapped(): Boolean {
        if (metadata.containsKey(ShapeMetadata.OPERATION_SHAPE)) {
            val operationShape = metadata[ShapeMetadata.OPERATION_SHAPE] as OperationShape
            if (operationShape.hasTrait<S3UnwrappedXmlOutputTrait>()) {
                return true
            }
        }
        return false
    }

    fun renderSingleMember(member: MemberShape, containerName: String, unkeyed: Boolean) {
        val memberTarget = ctx.model.expectShape(member.target)
        when (memberTarget) {
            is CollectionShape -> {
                renderListMember(member, memberTarget, containerName)
            }
            is MapShape -> {
                renderMapMember(member, memberTarget, containerName)
            }
            is TimestampShape -> {
                renderTimestampMember(member, memberTarget, containerName)
            }
            is BlobShape -> {
                renderBlobMember(member, memberTarget, containerName)
            }
            else -> {
                renderScalarMember(member, memberTarget, containerName, unkeyed)
            }
        }
    }

    override fun renderAssigningDecodedMember(memberName: String, decodedMemberName: String, isBoxed: Boolean) {
        writer.write("$memberName = $decodedMemberName")
    }
    override fun renderAssigningSymbol(memberName: String, symbol: String) {
        writer.write("$memberName = $symbol")
    }
    override fun renderAssigningNil(memberName: String) {
        writer.write("$memberName = nil")
    }
}
