/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings

class SwiftDelegatorTests {
    @Test
    fun `it renders files into namespace`() {

        val model = javaClass.getResource("simple-service-with-operation.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")

        SwiftCodegenPlugin().execute(context)

        assertTrue(manifest.hasFile("Sources/example/models/GetFooInput.swift"))
        assertTrue(manifest.hasFile("Sources/example/models/GetFooOutput.swift"))
        assertTrue(manifest.hasFile("Sources/example/models/GetFooError.swift"))
    }

    @Test
    fun `it vends writers for shapes`() {
        val model = javaClass.getResource("simple-service-with-operation.smithy").asSmithy()
        val getFooInputShape = model.expectShape(ShapeId.from("smithy.example#GetFooInput"))
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)

        val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
        val symbolProvider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings)
        val delegator = SwiftDelegator(settings, model, manifest, symbolProvider)

        delegator.useShapeWriter(getFooInputShape, { writer -> writer.write("Hello!") })
        delegator.flushWriters()
        assertEquals(
            settings.copyrightNotice + "\n\nHello!\n",
            manifest.getFileString("Sources/example/models/GetFooInput.swift").get()
        )
    }

    @Test
    fun `it uses opened writer separating with newline`() {
        val model = javaClass.getResource("simple-service-with-operation.smithy").asSmithy()
        val getFooInputShape = model.expectShape(ShapeId.from("smithy.example#GetFooInput"))
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)
        val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
        val symbolProvider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings)
        val delegator = SwiftDelegator(settings, model, manifest, symbolProvider)

        delegator.useShapeWriter(getFooInputShape, { writer -> writer.write("Hello!") })
        delegator.useShapeWriter(getFooInputShape, { writer -> writer.write("Goodbye!") })
        delegator.flushWriters()
        assertEquals(
            settings.copyrightNotice + "\n\nHello!\n\nGoodbye!\n",
            manifest.getFileString("Sources/example/models/GetFooInput.swift").get()
        )
    }
}
