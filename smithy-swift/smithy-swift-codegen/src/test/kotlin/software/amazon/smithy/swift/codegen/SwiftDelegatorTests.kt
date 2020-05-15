/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package software.amazon.smithy.swift.codegen

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ShapeId

class SwiftDelegatorTests : TestsBase() {
    @Test
    fun `it renders files into namespace`() {

        val model = createModelFromSmithy("simple-service-with-operation.smithy")
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)

        SwiftCodegenPlugin().execute(context)

        assertTrue(manifest.hasFile("example/models/GetFooInput.swift"))
        assertTrue(manifest.hasFile("example/models/GetFooOutput.swift"))
        assertTrue(manifest.hasFile("example/models/GetFooError.swift"))
    }

    @Test
    fun `it vends writers for shapes`() {
        val model = createModelFromSmithy("simple-service-with-operation.smithy")
        val getFooInputShape = model.expectShape(ShapeId.from("smithy.example#GetFooInput"))
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)

        val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
        val symbolProvider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings.moduleName)
        val delegator: SwiftDelegator = SwiftDelegator(settings, model, manifest, symbolProvider)

        delegator.useShapeWriter(getFooInputShape, { writer -> writer.write("Hello!") })
        delegator.flushWriters()
        assertEquals(SwiftWriter.staticHeader + "\n\nHello!\n",
            manifest.getFileString("example/models/GetFooInput.swift").get())
    }

    @Test
    fun `it uses opened writer separating with newline`() {
        val model = createModelFromSmithy("simple-service-with-operation.smithy")
        val getFooInputShape = model.expectShape(ShapeId.from("smithy.example#GetFooInput"))
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)
        val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
        val symbolProvider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings.moduleName)
        val delegator: SwiftDelegator = SwiftDelegator(settings, model, manifest, symbolProvider)

        delegator.useShapeWriter(getFooInputShape, { writer -> writer.write("Hello!") })
        delegator.useShapeWriter(getFooInputShape, { writer -> writer.write("Goodbye!") })
        delegator.flushWriters()
        assertEquals(SwiftWriter.staticHeader + "\n\nHello!\n\nGoodbye!\n",
            manifest.getFileString("example/models/GetFooInput.swift").get())
    }
}
