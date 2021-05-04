package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.SensitiveTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class CustomStringCustomStringConvertibleGenerator(private val model: Model,
                                                   private val symbolProvider: SymbolProvider,
                                                   private val writer: SwiftWriter,
                                                   private val shape: StructureShape,
                                                   private val protocolGenerator: ProtocolGenerator? = null
) {

    private val structSymbol: Symbol by lazy {
        symbolProvider.toSymbol(shape)
    }

    fun render() {
        writer.putContext("struct.name", structSymbol.name)
        writer.openBlock("extension \$struct.name:L: CustomStringConvertible {", "}") {
            if (shape.hasTrait(SensitiveTrait::class.java)) {
                writer.openBlock("public var description: String {", "}") {
                    writer.write("return \"** redacted **\"")
                }
            } else {
                //loop through each member.
            }
        }
    }
}