package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeDecodeGeneratable

abstract class MemberShapeDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeGeneratable {

    fun renderListMember(
        member: MemberShape,
        memberTarget: CollectionShape,
        containerName: String
    ) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        val listContainerName = "${memberName}Container"
        writer.write("let $listContainerName = try $containerName.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .$memberName)")

        val decodedTempVariableName = "${memberName}Decoded0"
        val itemContainerName = "${memberName}ItemContainer"
        val memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        writer.write("let $itemContainerName = try $listContainerName.decodeIfPresent(${memberTargetSymbol.name}.self, forKey: .member)")
        writer.write("var $decodedTempVariableName:\$T = nil", memberTargetSymbol)
        writer.openBlock("if let $itemContainerName = $itemContainerName {", "}") {
            writer.write("$decodedTempVariableName = $memberTargetSymbol()")

            val nestedTarget = ctx.model.expectShape(memberTarget.member.target)
            renderListMemberItems(nestedTarget, decodedTempVariableName, itemContainerName)
        }
        writer.write("\$L = \$L", memberName, decodedTempVariableName)
    }

    private fun renderListMemberItems(shape: Shape, decodedMemberName: String, collectionName: String) {
        val iteratorName = "${shape.type.name.toLowerCase()}0"
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (shape) {
                is TimestampShape -> {
                    throw Exception("renderListMemberItems: timestamp not supported")
                }
                is CollectionShape -> {
                    throw Exception("renderListMemberItems: recursive collections not supported")
                }
                is MapShape -> {
                    throw Exception("renderListMemberItems: maps not supported")
                }
                else -> {
                    writer.write("$decodedMemberName?.append($iteratorName)")
                }
            }
        }
    }
}
