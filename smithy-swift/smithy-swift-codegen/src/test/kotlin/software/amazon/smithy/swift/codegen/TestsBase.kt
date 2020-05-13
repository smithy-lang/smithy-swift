package software.amazon.smithy.swift.codegen

import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.loader.ModelAssembler
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.utils.CodeWriter
import java.net.URL
import java.util.logging.Logger

open class TestsBase {

    protected val LOGGER: Logger = Logger.getLogger(TestsBase::class.java.name)

    protected fun createModelFromSmithy(smithyTestResourceName: String): Model {
        return Model.assembler()
            .addImport(getSmithyResource(smithyTestResourceName = smithyTestResourceName))
            .discoverModels()
            .assemble()
            .unwrap()
    }

    protected fun createSymbolProvider(): SymbolProvider? {
        return SymbolProvider { shape: Shape ->
            Symbol.builder()
                .name(shape.id.name)
                .namespace(shape.id.namespace, "/")
                .definitionFile(shape.id.name + ".txt")
                .build()
        }
    }

    private fun getSmithyResource(smithyTestResourceName: String): URL? {
        return TestsBase::class.java.classLoader.getResource("software.amazon.smithy.swift.codegen/$smithyTestResourceName")
    }

    protected fun createModelFromShapes(vararg shapes: Shape): Model {
        return Model.assembler()
                    .addShapes(*shapes)
                    .assemble()
                    .unwrap()
    }


//    @Test
//    fun testCodeWriter() {
//        val writer: CodeWriter = CodeWriter.createDefault()
//        writer.openBlock("arr{", "}") {
//            writer.openBlock("return [", "]") {
//                writer.write(".A\n.B")
//            }
//        }
////        writer.pushState()
////        writer.write("Hello, \$L", "there! how di")
////        print(writer.toString())
////        writer.popState()
//        print(writer.toString())
//    }
}
