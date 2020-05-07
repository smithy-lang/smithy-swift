package software.amazon.smithy.swift.codegen

import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.utils.ListUtils
import software.amazon.smithy.utils.Pair
import java.util.*

class SwiftDelegatorTests: TestsBase() {
    @Test
    fun `it renders files into namespace`() {

        val model = createModelFromSmithy(smithyTestResourceName = "simple-service-with-operation.smithy")
        val manifest = MockManifest()
        val context = PluginContext.builder()
            .model(model)
            .fileManifest(manifest)
            .settings(
                Node.objectNodeBuilder()
                    .withMember("service", Node.from("smithy.example#Example"))
                    .withMember("module", Node.from("example"))
                    .withMember("moduleVersion", Node.from("0.1.0"))
                    .build()
            )
            .build()

        SwiftCodegenPlugin().execute(context)

        Assertions.assertTrue(manifest.hasFile("example/models/GetFooInput.swift"))
        Assertions.assertTrue(manifest.hasFile("example/models/GetFooOutput.swift"))
        Assertions.assertTrue(manifest.hasFile("example/models/GetFooError.swift"))
    }

    @Test
    fun `it vends writers for shapes`() {
        val model = createModelFromSmithy(smithyTestResourceName = "simple-service-with-operation.smithy")
        val getFooInputShape = model!!.expectShape(ShapeId.from("smithy.example#GetFooInput"))
        val manifest = MockManifest()
        val context = PluginContext.builder()
            .model(model)
            .fileManifest(manifest)
            .settings(
                Node.objectNodeBuilder()
                    .withMember("service", Node.from("smithy.example#Example"))
                    .withMember("module", Node.from("example"))
                    .withMember("moduleVersion", Node.from("0.1.0"))
                    .build()
            )
            .build()

        val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
        val symbolProvider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings.moduleName)
        val delegator: SwiftDelegator = SwiftDelegator(settings, model, manifest, symbolProvider)

        delegator.useShapeWriter(getFooInputShape, { writer -> writer.write("Hello!") })
        delegator.flushWriters()
        Assertions.assertEquals(SwiftWriter.staticHeader + "Hello!\n",
                                manifest.getFileString("example/models/GetFooInput.swift").get())
    }

    @Test
    fun `it uses opened writer separating with newline`() {
        val model = createModelFromSmithy(smithyTestResourceName = "simple-service-with-operation.smithy")
        val getFooInputShape = model!!.expectShape(ShapeId.from("smithy.example#GetFooInput"))
        val manifest = MockManifest()
        val context = PluginContext.builder()
            .model(model)
            .fileManifest(manifest)
            .settings(
                Node.objectNodeBuilder()
                    .withMember("service", Node.from("smithy.example#Example"))
                    .withMember("module", Node.from("example"))
                    .withMember("moduleVersion", Node.from("0.1.0"))
                    .build()
            )
            .build()

        val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
        val symbolProvider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings.moduleName)
        val delegator: SwiftDelegator = SwiftDelegator(settings, model, manifest, symbolProvider)

        delegator.useShapeWriter(getFooInputShape, { writer -> writer.write("Hello!") })
        delegator.useShapeWriter(getFooInputShape, { writer -> writer.write("Goodbye!") })
        delegator.flushWriters()
        Assertions.assertEquals(SwiftWriter.staticHeader + "Hello!\n\nGoodbye!\n",
                                manifest.getFileString("example/models/GetFooInput.swift").get())
    }

}