/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.StructureGenerator
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftWriter
import java.util.function.Consumer

class StructureGeneratorTests {
    @Test
    fun `it renders non-error structures`() {

        val struct: StructureShape = createStructureWithoutErrorTrait()
        val model: Model = createModelWithStructureShape(struct)
        val swiftSettings = model.defaultSettings()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, swiftSettings)
        val writer = SwiftWriter("MockPackage")
        val generator = StructureGenerator(model, provider, writer, struct, swiftSettings)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)
        val expectedGeneratedStructure =
            """
                /// This *is* documentation about the shape.
                public struct MyStruct: Equatable {
                    public let bar: Int
                    /// This *is* documentation about the member.
                    public let baz: Int?
                    public let foo: String?

                    public init (
                        bar: Int = 0,
                        baz: Int? = nil,
                        foo: String? = nil
                    )
                    {
                        self.bar = bar
                        self.baz = baz
                        self.foo = foo
                    }
                }
            """.trimIndent()
        contents.shouldContain(expectedGeneratedStructure)
    }

    @Test
    fun `it renders struct with primitive types`() {
        val model = javaClass.getResource("primitive-type-encode-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val primitiveTypesInput = manifest
            .getFileString("example/models/PrimitiveTypesInput.swift").get()
        Assertions.assertNotNull(primitiveTypesInput)
        val expected =
        """
        public struct PrimitiveTypesInput: Equatable {
            public let booleanVal: Swift.Bool?
            public let byteVal: Swift.Int8?
            public let doubleVal: Swift.Double?
            public let floatVal: Swift.Float?
            public let intVal: Swift.Int?
            public let longVal: Swift.Int?
            public let primitiveBooleanVal: Swift.Bool
            public let primitiveByteVal: Swift.Int8
            public let primitiveDoubleVal: Swift.Double
            public let primitiveFloatVal: Swift.Float
            public let primitiveIntVal: Swift.Int
            public let primitiveLongVal: Swift.Int
            public let primitiveShortVal: Swift.Int16
            public let shortVal: Swift.Int16?
            public let str: Swift.String?
        
            public init (
                booleanVal: Swift.Bool? = nil,
                byteVal: Swift.Int8? = nil,
                doubleVal: Swift.Double? = nil,
                floatVal: Swift.Float? = nil,
                intVal: Swift.Int? = nil,
                longVal: Swift.Int? = nil,
                primitiveBooleanVal: Swift.Bool = false,
                primitiveByteVal: Swift.Int8 = 0,
                primitiveDoubleVal: Swift.Double = 0.0,
                primitiveFloatVal: Swift.Float = 0.0,
                primitiveIntVal: Swift.Int = 0,
                primitiveLongVal: Swift.Int = 0,
                primitiveShortVal: Swift.Int16 = 0,
                shortVal: Swift.Int16? = nil,
                str: Swift.String? = nil
            )
            {
                self.booleanVal = booleanVal
                self.byteVal = byteVal
                self.doubleVal = doubleVal
                self.floatVal = floatVal
                self.intVal = intVal
                self.longVal = longVal
                self.primitiveBooleanVal = primitiveBooleanVal
                self.primitiveByteVal = primitiveByteVal
                self.primitiveDoubleVal = primitiveDoubleVal
                self.primitiveFloatVal = primitiveFloatVal
                self.primitiveIntVal = primitiveIntVal
                self.primitiveLongVal = primitiveLongVal
                self.primitiveShortVal = primitiveShortVal
                self.shortVal = shortVal
                self.str = str
            }
        }
        """.trimIndent()
        primitiveTypesInput.shouldContain(expected)
    }

    @Test
    fun `it renders recursive nested shapes`() {
        val structs = createStructureContainingNestedRecursiveShape()
        val model = javaClass.getResource("recursive-shape-test.smithy").asSmithy()
        val swiftSettings = model.defaultSettings()
        val provider = SwiftCodegenPlugin.createSymbolProvider(model, swiftSettings)
        val writer = SwiftWriter("MockPackage")

        for (struct in structs) {
            val generator = StructureGenerator(model, provider, writer, struct, swiftSettings)
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
    public let recursiveMember: RecursiveShapesInputOutputNested1?

    public init (
        bar: String? = nil,
        recursiveMember: RecursiveShapesInputOutputNested1? = nil
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
        val model = javaClass.getResource("recursive-shape-test.smithy").asSmithy()
        val swiftSettings = model.defaultSettings()
        val provider = SwiftCodegenPlugin.createSymbolProvider(model, swiftSettings)
        val writer = SwiftWriter("MockPackage")

        for (struct in structs) {
            val generator = StructureGenerator(model, provider, writer, struct, swiftSettings)
            generator.render()
        }
        val contents = writer.toString()
        val expected =
            """
public struct RecursiveShapesInputOutputNestedList1: Equatable {
    public let foo: String?
    public let recursiveList: [RecursiveShapesInputOutputNested2]?

    public init (
        foo: String? = nil,
        recursiveList: [RecursiveShapesInputOutputNested2]? = nil
    )
    {
        self.foo = foo
        self.recursiveList = recursiveList
    }
}

public struct RecursiveShapesInputOutputNested2: Equatable {
    public let bar: String?
    public let recursiveMember: RecursiveShapesInputOutputNested1?

    public init (
        bar: String? = nil,
        recursiveMember: RecursiveShapesInputOutputNested1? = nil
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
        val swiftSettings = model.defaultSettings()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, swiftSettings)
        val writer = SwiftWriter("MockPackage")
        val generator = StructureGenerator(model, provider, writer, struct, swiftSettings)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)
        val expectedGeneratedStructure =
            """
                import ClientRuntime

                /// This *is* documentation about the shape.
                public struct MyError: ClientRuntime.ServiceError, Equatable {
                    public var _headers: ClientRuntime.Headers?
                    public var _statusCode: ClientRuntime.HttpStatusCode?
                    public var _message: Swift.String?
                    public var _requestID: Swift.String?
                    public var _retryable: Swift.Bool = true
                    public var _isThrottling: Swift.Bool = false
                    public var _type: ClientRuntime.ErrorType = .client
                    /// This *is* documentation about the member.
                    public var baz: Swift.Int?
                    public var message: Swift.String?
                
                    public init (
                        baz: Swift.Int? = nil,
                        message: Swift.String? = nil
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
        struct.allMembers.values.forEach(
            Consumer { shape: MemberShape? ->
                assembler.addShape(
                    shape
                )
            }
        )

        return assembler.assemble().unwrap()
    }

    @Test
    fun `check for sparse and dense datatypes in list`() {
        val model = javaClass.getResource("sparse-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)
        val contents = getModelFileContents("example", "JsonListsInput.swift", manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents =
            """
            public struct JsonMapsInput: Equatable {
                public let denseBooleanMap: [Swift.String:Swift.Bool]?
                public let denseNumberMap: [Swift.String:Swift.Int]?
                public let denseStringMap: [Swift.String:Swift.String]?
                public let denseStructMap: [Swift.String:ExampleClientTypes.GreetingStruct]?
                public let sparseBooleanMap: [Swift.String:Swift.Bool?]?
                public let sparseNumberMap: [Swift.String:Swift.Int?]?
                public let sparseStringMap: [Swift.String:Swift.String?]?
                public let sparseStructMap: [Swift.String:ExampleClientTypes.GreetingStruct?]?
            
                public init (
                    denseBooleanMap: [Swift.String:Swift.Bool]? = nil,
                    denseNumberMap: [Swift.String:Swift.Int]? = nil,
                    denseStringMap: [Swift.String:Swift.String]? = nil,
                    denseStructMap: [Swift.String:ExampleClientTypes.GreetingStruct]? = nil,
                    sparseBooleanMap: [Swift.String:Swift.Bool?]? = nil,
                    sparseNumberMap: [Swift.String:Swift.Int?]? = nil,
                    sparseStringMap: [Swift.String:Swift.String?]? = nil,
                    sparseStructMap: [Swift.String:ExampleClientTypes.GreetingStruct?]? = nil
                )
                {
                    self.denseBooleanMap = denseBooleanMap
                    self.denseNumberMap = denseNumberMap
                    self.denseStringMap = denseStringMap
                    self.denseStructMap = denseStructMap
                    self.sparseBooleanMap = sparseBooleanMap
                    self.sparseNumberMap = sparseNumberMap
                    self.sparseStringMap = sparseStringMap
                    self.sparseStructMap = sparseStructMap
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `check for sparse and dense datatypes in maps`() {
        /*  Also the integration test for model evolution: Struct JsonListsInputOutput is generating 2
            separate structs for input and output with members given in smithy model, without creating
            additional structs in the model
         */
        val model = javaClass.getResource("sparse-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val jsonMapsInput = manifest
            .getFileString("example/models/JsonMapsInput.swift").get()
        Assertions.assertNotNull(jsonMapsInput)
        val expectedJsonMapsInput =
            """
                public struct JsonMapsInput: Equatable {
                    public let denseBooleanMap: [String:Bool]?
                    public let denseNumberMap: [String:Int]?
                    public let denseStringMap: [String:String]?
                    public let denseStructMap: [String:GreetingStruct]?
                    public let sparseBooleanMap: [String:Bool?]?
                    public let sparseNumberMap: [String:Int?]?
                    public let sparseStringMap: [String:String?]?
                    public let sparseStructMap: [String:GreetingStruct?]?

                    public init (
                        denseBooleanMap: [String:Bool]? = nil,
                        denseNumberMap: [String:Int]? = nil,
                        denseStringMap: [String:String]? = nil,
                        denseStructMap: [String:GreetingStruct]? = nil,
                        sparseBooleanMap: [String:Bool?]? = nil,
                        sparseNumberMap: [String:Int?]? = nil,
                        sparseStringMap: [String:String?]? = nil,
                        sparseStructMap: [String:GreetingStruct?]? = nil
                    )
                    {
                        self.denseBooleanMap = denseBooleanMap
                        self.denseNumberMap = denseNumberMap
                        self.denseStringMap = denseStringMap
                        self.denseStructMap = denseStructMap
                        self.sparseBooleanMap = sparseBooleanMap
                        self.sparseNumberMap = sparseNumberMap
                        self.sparseStringMap = sparseStringMap
                        self.sparseStructMap = sparseStructMap
                    }
                }
            """.trimIndent()
        jsonMapsInput.shouldContain(expectedJsonMapsInput)

        val jsonMapsOutput = manifest
            .getFileString("example/models/JsonMapsOutputResponse.swift").get()
        Assertions.assertNotNull(jsonMapsOutput)
        val expectedJsonMapsOutput =
            """
                public struct JsonMapsOutputResponse: Equatable {
                    public let denseBooleanMap: [String:Bool]?
                    public let denseNumberMap: [String:Int]?
                    public let denseStringMap: [String:String]?
                    public let denseStructMap: [String:GreetingStruct]?
                    public let sparseBooleanMap: [String:Bool?]?
                    public let sparseNumberMap: [String:Int?]?
                    public let sparseStringMap: [String:String?]?
                    public let sparseStructMap: [String:GreetingStruct?]?

                    public init (
                        denseBooleanMap: [String:Bool]? = nil,
                        denseNumberMap: [String:Int]? = nil,
                        denseStringMap: [String:String]? = nil,
                        denseStructMap: [String:GreetingStruct]? = nil,
                        sparseBooleanMap: [String:Bool?]? = nil,
                        sparseNumberMap: [String:Int?]? = nil,
                        sparseStringMap: [String:String?]? = nil,
                        sparseStructMap: [String:GreetingStruct?]? = nil
                    )
                    {
                        self.denseBooleanMap = denseBooleanMap
                        self.denseNumberMap = denseNumberMap
                        self.denseStringMap = denseStringMap
                        self.denseStructMap = denseStructMap
                        self.sparseBooleanMap = sparseBooleanMap
                        self.sparseNumberMap = sparseNumberMap
                        self.sparseStringMap = sparseStringMap
                        self.sparseStructMap = sparseStructMap
                    }
                }
            """.trimIndent()

        jsonMapsOutput.shouldContain(expectedJsonMapsOutput)
    }

    @Test
    fun `deprecated trait on structure`() {
        val model = javaClass.getResource("deprecated-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        var structWithDeprecatedTrait = manifest
            .getFileString("example/models/StructWithDeprecatedTrait.swift").get()
        Assertions.assertNotNull(structWithDeprecatedTrait)
        var structContainsDeprecatedTrait = """
        extension ExampleClientTypes {
            @available(*, deprecated, message: "This shape is no longer used. API deprecated since 1.3")
            public struct StructWithDeprecatedTrait: Equatable {
        """.trimIndent()
        structWithDeprecatedTrait.shouldContain(structContainsDeprecatedTrait)

        structWithDeprecatedTrait = manifest
            .getFileString("example/models/StructSincePropertySet.swift").get()
        Assertions.assertNotNull(structWithDeprecatedTrait)
        structContainsDeprecatedTrait = """
        extension ExampleClientTypes {
            @available(*, deprecated, message: " API deprecated since 2019-03-21")
            public struct StructSincePropertySet: Equatable {
        """.trimIndent()
        structWithDeprecatedTrait.shouldContain(structContainsDeprecatedTrait)
    }

    @Test
    fun `deprecated trait on synthetically cloned structure and structure member`() {
        val model = javaClass.getResource("deprecated-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val structWithDeprecatedTraitMember = manifest
            .getFileString("example/models/OperationWithDeprecatedTraitInput.swift").get()
        Assertions.assertNotNull(structWithDeprecatedTraitMember)
        val structContainsDeprecatedMember = """
        @available(*, deprecated, message: "This shape is no longer used. API deprecated since 1.3")
        public struct OperationWithDeprecatedTraitInput: Equatable {
            public let bool: Swift.Bool?
            public let foo: ExampleClientTypes.Foo?
            public let intVal: Swift.Int?
            @available(*, deprecated)
            public let string: Swift.String?
            @available(*, deprecated, message: " API deprecated since 2019-03-21")
            public let structSincePropertySet: ExampleClientTypes.StructSincePropertySet?
            @available(*, deprecated, message: "This shape is no longer used. API deprecated since 1.3")
            public let structWithDeprecatedTrait: ExampleClientTypes.StructWithDeprecatedTrait?
        """.trimIndent()
        structWithDeprecatedTraitMember.shouldContain(structContainsDeprecatedMember)
    }

    @Test
    fun `deprecated trait fetched from the target of a struct member`() {
        val model = javaClass.getResource("deprecated-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val structWithDeprecatedTraitMember = manifest
            .getFileString("example/models/Foo.swift").get()
        Assertions.assertNotNull(structWithDeprecatedTraitMember)
        val structContainsDeprecatedMember = """
        extension ExampleClientTypes {
            public struct Foo: Equatable {
                /// Test documentation with deprecated
                @available(*, deprecated)
                public let baz: Swift.String?
                /// Test documentation with deprecated
                public let qux: Swift.String?
        """.trimIndent()
        structWithDeprecatedTraitMember.shouldContain(structContainsDeprecatedMember)
    }
}
