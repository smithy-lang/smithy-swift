package software.amazon.smithy.swift.codegen

import java.net.URL
import java.util.logging.Logger
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.Shape

open class TestsBase {

    protected val LOGGER: Logger = Logger.getLogger(TestsBase::class.java.name)

    protected fun createModelFromSmithy(smithyTestResourceName: String): Model {
        return Model.assembler()
            .addImport(getSmithyResource(smithyTestResourceName = smithyTestResourceName))
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
}
