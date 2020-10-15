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
import io.kotest.matchers.string.shouldContainOnlyOnce
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
                "public struct MyStruct: Equatable {\n" +
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
    fun `it renders recursive nested shapes`() {
        val structs = createStructureContainingNestedRecursiveShape()
        val model = createModelFromSmithy("recursive-shape-test.smithy")
        val provider = SwiftCodegenPlugin.createSymbolProvider(model, "smithy.example")
        val writer = SwiftWriter("MockPackage")

        for (struct in structs) {
            val generator = StructureGenerator(model, provider, writer, struct)
            generator.render()
        }
        val contents = writer.toString()
        val expected =
            """
public struct RecursiveShapesInputOutputNested1: Equatable {
    public let foo: String?
    public let nested: Box<RecursiveShapesInputOutputNested2>?

    public init (
        foo: String? = nil,
        nested: Box<RecursiveShapesInputOutputNested2>? = nil
    )
    {
        self.foo = foo
        self.nested = nested
    }
}

public struct RecursiveShapesInputOutputNested2: Equatable {
    public let bar: String?
    public let recursiveMember: Box<RecursiveShapesInputOutputNested1>?

    public init (
        bar: String? = nil,
        recursiveMember: Box<RecursiveShapesInputOutputNested1>? = nil
    )
    {
        self.bar = bar
        self.recursiveMember = recursiveMember
    }
}

/// This *is* documentation about the shape.
public struct RecursiveShapesInputOutput: Equatable {
    public let nested: RecursiveShapesInputOutputNested1?

    public init (
        nested: RecursiveShapesInputOutputNested1? = nil
    )
    {
        self.nested = nested
    }
}
                """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders recursive nested shapes in lists`() {
        val structs = createStructureContainingNestedRecursiveShapeList()
        val model = createModelFromSmithy("recursive-shape-test.smithy")
        val provider = SwiftCodegenPlugin.createSymbolProvider(model, "smithy.example")
        val writer = SwiftWriter("MockPackage")

        for (struct in structs) {
            val generator = StructureGenerator(model, provider, writer, struct)
            generator.render()
        }
        val contents = writer.toString()
        val expected =
            """
public struct RecursiveShapesInputOutputNestedList1: Equatable {
    public let foo: String?
    public let recursiveList: [RecursiveShapesInputOutputNested2?]?

    public init (
        foo: String? = nil,
        recursiveList: [RecursiveShapesInputOutputNested2?]? = nil
    )
    {
        self.foo = foo
        self.recursiveList = recursiveList
    }
}

public struct RecursiveShapesInputOutputNested2: Equatable {
    public let bar: String?
    public let recursiveMember: Box<RecursiveShapesInputOutputNested1>?

    public init (
        bar: String? = nil,
        recursiveMember: Box<RecursiveShapesInputOutputNested1>? = nil
    )
    {
        self.bar = bar
        self.recursiveMember = recursiveMember
    }
}

/// This *is* documentation about the shape.
public struct RecursiveShapesInputOutputLists: Equatable {
    public let nested: RecursiveShapesInputOutputNested1?

    public init (
        nested: RecursiveShapesInputOutputNested1? = nil
    )
    {
        self.nested = nested
    }
}
                """.trimIndent()
        contents.shouldContainOnlyOnce(expected)
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
        val expectedGeneratedStructure =
            """
                import ClientRuntime

                /// This *is* documentation about the shape.
                public struct MyError: ServiceError {
                    public var _headers: HttpHeaders?
                    public var _statusCode: HttpStatusCode?
                    public var _message: String?
                    public var _requestID: String?
                    public var _retryable: Bool? = true
                    public var _type: ErrorType = .client
                    /// This *is* documentation about the member.
                    public var baz: Int?
                    public var message: String?

                    public init (
                        baz: Int? = nil,
                        message: String? = nil
                    )
                    {
                        self.baz = baz
                        self.message = message
                    }
                }
            """.trimIndent()

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
