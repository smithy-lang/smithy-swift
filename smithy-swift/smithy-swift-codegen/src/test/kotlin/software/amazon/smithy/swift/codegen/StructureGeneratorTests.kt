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
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.StructureShape

class StructureGeneratorTests : TestsBase() {
    @Test
    fun `it renders non-error structures`() {

        val struct: StructureShape = createStructureWithoutErrorTrait()
        val model: Model = createModelWithStructureShape(struct)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val writer = SwiftWriter("MockPackage")
        val generator = StructureGenerator(model, provider, writer, struct)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)
        val expectedGeneratedStructure = "" +
                "/// This *is* documentation about the shape.\n" +
                "public struct MyStruct {\n" +
                "    public let bar: Int\n" +
                "    /// This *is* documentation about the member.\n" +
                "    public let baz: Int?\n" +
                "    public let foo: String?\n" +
                "\n" +
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
                "}"

        contents.shouldContain(expectedGeneratedStructure)
    }

    @Test
    fun `it renders error structures along with proper import statement`() {

        val struct: StructureShape = createStructureWithOptionalErrorMessage()
        val model: Model = createModelWithStructureShape(struct)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val writer = SwiftWriter("MockPackage")
        val generator = StructureGenerator(model, provider, writer, struct)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)
        val expectedGeneratedStructure = "" +
                "import ClientRuntime\n" +
                "\n" +
                "/// This *is* documentation about the shape.\n" +
                "public struct MyError: HttpOperationError {\n" +
                "    public var httpResponse: HttpResponse\n" +
                "    public var retryable = true\n" +
                "    public var type: ErrorType = .client\n" +
                "    /// This *is* documentation about the member.\n" +
                "    public var baz: Int?\n" +
                "    public var message: String?\n" +
                "\n" +
                "    public init (\n" +
                "        httpResponse: HttpResponse,\n" +
                "        baz: Int? = nil,\n" +
                "        message: String? = nil\n" +
                "    )\n" +
                "    {\n" +
                "        self.httpResponse = httpResponse\n" +
                "        self.baz = baz\n" +
                "        self.message = message\n" +
                "    }\n" +
                "}"

        contents.shouldContain(expectedGeneratedStructure)
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
