package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.ErrorTrait


class StructureGenerator(private val model: Model,
                         private val symbolProvider: SymbolProvider,
                         private val writer: SwiftWriter,
                         private val shape: StructureShape) {
    fun render() {
        if (!shape.hasTrait(ErrorTrait::class.java)) {
            renderStructure()
        } else {
           // renderErrorStructure()
        }
    }

    /**
     * Renders a normal, non-error structure.
     */
    private fun renderStructure() {
        val symbol: Symbol = symbolProvider.toSymbol(shape)
        //writer.writeShapeDocs(shape)
        writer.openBlock("public struct \$L {", symbol.name)
        for (member in shape.allMembers.values) {
            val memberName = symbolProvider.toMemberName(member)
           // writer.writeMemberDocs(model, member)
            writer.write("public let \$L: \$T", memberName, symbolProvider.toSymbol(member))
        }
        writer.closeBlock("}").write("")
    }
}