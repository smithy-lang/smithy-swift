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

import io.kotest.matchers.string.shouldContain
import java.util.function.Consumer
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.DocumentationTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.HttpErrorTrait
import software.amazon.smithy.model.traits.RetryableTrait

class StructureGeneratorTests : TestsBase() {
    @Test
    fun `it renders non-error structures`() {

        val struct: StructureShape = createStructureWithoutErrorTrait()
        val model: Model = createModelWithStructureShape(struct)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val writer = SwiftWriter("MockPackage")
        val generator = StructureGenerator(model, provider, writer, struct, "Example")
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)
        val expectedGeneratedStructure = "" +
                "/// This *is* documentation about the shape.\n" +
                "public struct MyStruct {\n" +
                "    public let bar: Int\n" +
                "    /// This *is* documentation about the member.\n" +
                "    public let baz: Int?\n" +
                "    public let foo: String?\n\n" +
                "    public init (\n" +
                "        bar: Int = 0,\n" +
                "        baz: Int? = nil,\n" +
                "        foo: String? = nil\n" +
                "    )\n" +
                "    {\n" +
                "        self.bar = bar\n" +
                "        self.baz = baz\n" +
                "        self.foo = foo\n" +
                "    }\n" +
                "}\n"

        contents.shouldContain(expectedGeneratedStructure)
    }

    @Test
    fun `it renders error structures`() {

        val struct: StructureShape = createStructureWithOptionalErrorMessage()
        val model: Model = createModelWithStructureShape(struct)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val writer = SwiftWriter("MockPackage")
        val generator = StructureGenerator(model, provider, writer, struct, "Example")
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)
        val expectedGeneratedStructure = "" +
                "/// This *is* documentation about the shape.\n" +
                "public struct MyError: Exception {\n" +
                "    public let errorType = .client\n" +
                "    public let httpErrorCode = 429\n" +
                "    public let isRetryable = true\n" +
                "    public let serviceName = Example\n" +
                "    /// This *is* documentation about the member.\n" +
                "    public let baz: Int?\n" +
                "    public let message: String?\n" +
                "\n" +
                "    public init (\n" +
                "        baz: Int? = nil,\n" +
                "        message: String? = nil\n" +
                "    )\n" +
                "    {\n" +
                "        self.baz = baz\n" +
                "        self.message = message\n" +
                "    }\n" +
                "}\n"

        contents.shouldContain(expectedGeneratedStructure)
    }

    @Test
    fun `it imports ClientRuntime dependency`() {
        val model = createModelFromSmithy("error-test-optional-message.smithy")
        val errorStructureShape = model.expectShape(ShapeId.from("smithy.example#Err"))
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)
        val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
        val symbolProvider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings.moduleName)
        val delegator: SwiftDelegator = SwiftDelegator(settings, model, manifest, symbolProvider)

        delegator.useShapeWriter(errorStructureShape) {
            writer: SwiftWriter -> StructureGenerator(model, symbolProvider, writer,
            errorStructureShape as StructureShape, settings.service.name).render()
        }
        delegator.flushWriters()

        val contents = manifest.getFileString("example/models/Err.swift").get()

        val expectedGeneratedStructure = "" +
                "import ClientRuntime\n" +
                "\n" +
                "public struct Err: Exception {\n" +
                "    public let errorType = .client\n" +
                "    public let isRetryable = false\n" +
                "    public let serviceName = Example\n" +
                "    public let message: String?\n" +
                "\n" +
                "    public init (\n" +
                "        message: String? = nil\n" +
                "    )\n" +
                "    {\n" +
                "        self.message = message\n" +
                "    }\n" +
                "}\n"

        contents.shouldContain(expectedGeneratedStructure)
    }

    private fun createStructureWithoutErrorTrait(): StructureShape {
        val member1 = MemberShape.builder().id("smithy.example#MyStruct\$foo").target("smithy.api#String").build()
        val member2 = MemberShape.builder().id("smithy.example#MyStruct\$bar").target("smithy.api#PrimitiveInteger").build()
        val member3 = MemberShape.builder().id("smithy.example#MyStruct\$baz")
            .target("smithy.api#Integer")
            .addTrait(DocumentationTrait("This *is* documentation about the member."))
            .build()

        return StructureShape.builder()
            .id("smithy.example#MyStruct")
            .addMember(member1)
            .addMember(member2)
            .addMember(member3)
            .addTrait(DocumentationTrait("This *is* documentation about the shape."))
            .build()
    }

    private fun createStructureWithOptionalErrorMessage(): StructureShape {
        val member1 = MemberShape.builder().id("smithy.example#MyError\$message")
            .target("smithy.api#String")
            .build()
        val member2 = MemberShape.builder().id("smithy.example#MyError\$baz")
            .target("smithy.api#Integer")
            .addTrait(DocumentationTrait("This *is* documentation about the member."))
            .build()

        return StructureShape.builder()
            .id("smithy.example#MyError")
            .addMember(member1)
            .addMember(member2)
            .addTrait(DocumentationTrait("This *is* documentation about the shape."))
            .addTrait(ErrorTrait("client"))
            .addTrait(RetryableTrait.builder().build())
            .addTrait(HttpErrorTrait(429))
            .build()
    }

    private fun createModelWithStructureShape(struct: StructureShape): Model {

        val assembler = Model.assembler().addShape(struct)
        struct.allMembers.values.forEach(Consumer { shape: MemberShape? ->
            assembler.addShape(
                shape
            )
        })

        return assembler.assemble().unwrap()
    }
}
