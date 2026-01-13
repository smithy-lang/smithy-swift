package software.amazon.smithy.swift.codegen.basicshapes

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
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.StructureGenerator
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.asSmithy
import software.amazon.smithy.swift.codegen.buildMockPluginContext
import software.amazon.smithy.swift.codegen.createModelWithStructureWithoutErrorTrait
import software.amazon.smithy.swift.codegen.createStructureContainingNestedRecursiveShape
import software.amazon.smithy.swift.codegen.createStructureContainingNestedRecursiveShapeList
import software.amazon.smithy.swift.codegen.createStructureWithOptionalErrorMessage
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.getModelFileContents
import software.amazon.smithy.swift.codegen.shouldSyntacticSanityCheck
import java.util.function.Consumer

class StructureGeneratorTests {
    @Test
    fun `it renders non-error structures`() {
        val model = createModelWithStructureWithoutErrorTrait()
        val swiftSettings = model.defaultSettings()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, swiftSettings)
        val writer = SwiftWriter("MockPackage")
        val struct = model.getShape(ShapeId.from("smithy.example#MyStruct")).get() as StructureShape
        val generator = StructureGenerator(model, provider, writer, struct, swiftSettings)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(swiftSettings.copyrightNotice)
        val expectedGeneratedStructure = """
/// This is documentation about the shape.
public struct MyStruct: Swift.Sendable {
    public var bar: Swift.Int
    /// This is documentation about the member.
    public var baz: Swift.Int?
    public var foo: Swift.String?

    public init(
        bar: Swift.Int = 0,
        baz: Swift.Int? = nil,
        foo: Swift.String? = nil
    ) {
        self.bar = bar
        self.baz = baz
        self.foo = foo
    }
}
"""
        contents.shouldContain(expectedGeneratedStructure)
    }

    @Test
    fun `it renders struct with primitive types`() {
        val model = javaClass.classLoader.getResource("primitive-type-encode-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val primitiveTypesInput =
            manifest
                .getFileString("Sources/example/models/PrimitiveTypesInput.swift")
                .get()
        Assertions.assertNotNull(primitiveTypesInput)
        val expected = """
public struct PrimitiveTypesInput: Swift.Sendable {
    public var booleanVal: Swift.Bool?
    public var byteVal: Swift.Int8?
    public var doubleVal: Swift.Double?
    public var floatVal: Swift.Float?
    public var intVal: Swift.Int?
    public var longVal: Swift.Int?
    public var primitiveBooleanVal: Swift.Bool
    public var primitiveByteVal: Swift.Int8
    public var primitiveDoubleVal: Swift.Double
    public var primitiveFloatVal: Swift.Float
    public var primitiveIntVal: Swift.Int
    public var primitiveLongVal: Swift.Int
    public var primitiveShortVal: Swift.Int16
    public var shortVal: Swift.Int16?
    public var str: Swift.String?

    public init(
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
    ) {
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
"""
        primitiveTypesInput.shouldContain(expected)
    }

    @Test
    fun `it renders recursive nested shapes`() {
        val structs = createStructureContainingNestedRecursiveShape()
        val model = javaClass.classLoader.getResource("recursive-shape-test.smithy").asSmithy()
        val swiftSettings = model.defaultSettings()
        val provider = SwiftCodegenPlugin.createSymbolProvider(model, swiftSettings)
        val writer = SwiftWriter("MockPackage")

        for (struct in structs) {
            val generator = StructureGenerator(model, provider, writer, struct, swiftSettings)
            generator.render()
        }
        val contents = writer.toString()
        val expected = """
public struct RecursiveShapesInputOutputNested1: Swift.Sendable {
    public var foo: Swift.String?
    @Indirect public var nested: RecursiveShapesInputOutputNested2?

    public init(
        foo: Swift.String? = nil,
        nested: RecursiveShapesInputOutputNested2? = nil
    ) {
        self.foo = foo
        self.nested = nested
    }
}

public struct RecursiveShapesInputOutputNested2: Swift.Sendable {
    public var bar: Swift.String?
    public var recursiveMember: RecursiveShapesInputOutputNested1?

    public init(
        bar: Swift.String? = nil,
        recursiveMember: RecursiveShapesInputOutputNested1? = nil
    ) {
        self.bar = bar
        self.recursiveMember = recursiveMember
    }
}

/// This is documentation about the shape.
public struct RecursiveShapesInputOutput: Swift.Sendable {
    public var nested: RecursiveShapesInputOutputNested1?

    public init(
        nested: RecursiveShapesInputOutputNested1? = nil
    ) {
        self.nested = nested
    }
}
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders recursive nested shapes in lists`() {
        val structs = createStructureContainingNestedRecursiveShapeList()
        val model = javaClass.classLoader.getResource("recursive-shape-test.smithy").asSmithy()
        val swiftSettings = model.defaultSettings()
        val provider = SwiftCodegenPlugin.createSymbolProvider(model, swiftSettings)
        val writer = SwiftWriter("MockPackage")

        for (struct in structs) {
            val generator = StructureGenerator(model, provider, writer, struct, swiftSettings)
            generator.render()
        }
        val contents = writer.toString()
        val expected = """
public struct RecursiveShapesInputOutputNestedList1: Swift.Sendable {
    public var foo: Swift.String?
    public var recursiveList: [RecursiveShapesInputOutputNested2]?

    public init(
        foo: Swift.String? = nil,
        recursiveList: [RecursiveShapesInputOutputNested2]? = nil
    ) {
        self.foo = foo
        self.recursiveList = recursiveList
    }
}

public struct RecursiveShapesInputOutputNested2: Swift.Sendable {
    public var bar: Swift.String?
    public var recursiveMember: RecursiveShapesInputOutputNested1?

    public init(
        bar: Swift.String? = nil,
        recursiveMember: RecursiveShapesInputOutputNested1? = nil
    ) {
        self.bar = bar
        self.recursiveMember = recursiveMember
    }
}

/// This is documentation about the shape.
public struct RecursiveShapesInputOutputLists: Swift.Sendable {
    public var nested: RecursiveShapesInputOutputNested1?

    public init(
        nested: RecursiveShapesInputOutputNested1? = nil
    ) {
        self.nested = nested
    }
}
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders error structures`() {
        val struct: StructureShape = createStructureWithOptionalErrorMessage()
        val model: Model = createModelWithStructureShape(struct)
        val swiftSettings = model.defaultSettings()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, swiftSettings)
        val writer = SwiftWriter("MockPackage")
        val generator = StructureGenerator(model, provider, writer, struct, swiftSettings)
        generator.renderErrors()

        val contents = writer.toString()

        contents.shouldContain(swiftSettings.copyrightNotice)
        val expectedGeneratedStructure = """
public struct MyError: ClientRuntime.ModeledError, ClientRuntime.ServiceError, ClientRuntime.HTTPError, Swift.Error, Swift.Sendable {

    public struct Properties: Swift.Sendable {
        /// This is documentation about the member.
        public internal(set) var baz: Swift.Int? = nil
        public internal(set) var message: Swift.String? = nil
    }

    public internal(set) var properties = Properties()
    public static var typeName: Swift.String { "MyError" }
    public static var fault: ClientRuntime.ErrorFault { .client }
    public static var isRetryable: Swift.Bool { true }
    public static var isThrottling: Swift.Bool { false }
    public internal(set) var httpResponse = SmithyHTTPAPI.HTTPResponse()
    public var message: Swift.String?
    public internal(set) var requestID: Swift.String?

    public init(
        baz: Swift.Int? = nil,
        message: Swift.String? = nil
    ) {
        self.properties.baz = baz
        self.properties.message = message
    }
}
"""
        contents.shouldContain(expectedGeneratedStructure)
    }

    private fun createModelWithStructureShape(struct: StructureShape): Model {
        val assembler = Model.assembler().addShape(struct)
        struct.allMembers.values.forEach(
            Consumer { shape: MemberShape? ->
                assembler.addShape(
                    shape,
                )
            },
        )

        return assembler.assemble().unwrap()
    }

    @Test
    fun `check for sparse and dense datatypes in list`() {
        val model = javaClass.classLoader.getResource("sparse-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)
        val contents = getModelFileContents("Sources/example", "JsonListsInput.swift", manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents = """
public struct JsonListsInput: Swift.Sendable {
    public var booleanList: [Swift.Bool]?
    public var integerList: [Swift.Int]?
    public var nestedStringList: [[Swift.String]]?
    public var sparseStringList: [Swift.String?]?
    public var stringList: [Swift.String]?
    public var stringSet: Swift.Set<Swift.String>?
    public var timestampList: [Foundation.Date]?

    public init(
        booleanList: [Swift.Bool]? = nil,
        integerList: [Swift.Int]? = nil,
        nestedStringList: [[Swift.String]]? = nil,
        sparseStringList: [Swift.String?]? = nil,
        stringList: [Swift.String]? = nil,
        stringSet: Swift.Set<Swift.String>? = nil,
        timestampList: [Foundation.Date]? = nil
    ) {
        self.booleanList = booleanList
        self.integerList = integerList
        self.nestedStringList = nestedStringList
        self.sparseStringList = sparseStringList
        self.stringList = stringList
        self.stringSet = stringSet
        self.timestampList = timestampList
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `check for sparse and dense datatypes in maps`() {
        /*  Also the integration test for model evolution: Struct JsonListsInputOutput is generating 2
            separate structs for input and output with members given in smithy model, without creating
            additional structs in the model
         */
        val model = javaClass.classLoader.getResource("sparse-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val jsonMapsInput =
            manifest
                .getFileString("Sources/example/models/JsonMapsInput.swift")
                .get()
        Assertions.assertNotNull(jsonMapsInput)
        val expectedJsonMapsInput = """
public struct JsonMapsInput: Swift.Sendable {
    public var denseBooleanMap: [Swift.String: Swift.Bool]?
    public var denseNumberMap: [Swift.String: Swift.Int]?
    public var denseStringMap: [Swift.String: Swift.String]?
    public var denseStructMap: [Swift.String: ExampleClientTypes.GreetingStruct]?
    public var sparseBooleanMap: [Swift.String: Swift.Bool?]?
    public var sparseNumberMap: [Swift.String: Swift.Int?]?
    public var sparseStringMap: [Swift.String: Swift.String?]?
    public var sparseStructMap: [Swift.String: ExampleClientTypes.GreetingStruct?]?

    public init(
        denseBooleanMap: [Swift.String: Swift.Bool]? = nil,
        denseNumberMap: [Swift.String: Swift.Int]? = nil,
        denseStringMap: [Swift.String: Swift.String]? = nil,
        denseStructMap: [Swift.String: ExampleClientTypes.GreetingStruct]? = nil,
        sparseBooleanMap: [Swift.String: Swift.Bool?]? = nil,
        sparseNumberMap: [Swift.String: Swift.Int?]? = nil,
        sparseStringMap: [Swift.String: Swift.String?]? = nil,
        sparseStructMap: [Swift.String: ExampleClientTypes.GreetingStruct?]? = nil
    ) {
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
"""
        jsonMapsInput.shouldContain(expectedJsonMapsInput)

        val jsonMapsOutput =
            manifest
                .getFileString("Sources/example/models/JsonMapsOutput.swift")
                .get()
        Assertions.assertNotNull(jsonMapsOutput)
        val expectedJsonMapsOutput = """
public struct JsonMapsOutput: Swift.Sendable {
    public var denseBooleanMap: [Swift.String: Swift.Bool]?
    public var denseNumberMap: [Swift.String: Swift.Int]?
    public var denseStringMap: [Swift.String: Swift.String]?
    public var denseStructMap: [Swift.String: ExampleClientTypes.GreetingStruct]?
    public var sparseBooleanMap: [Swift.String: Swift.Bool?]?
    public var sparseNumberMap: [Swift.String: Swift.Int?]?
    public var sparseStringMap: [Swift.String: Swift.String?]?
    public var sparseStructMap: [Swift.String: ExampleClientTypes.GreetingStruct?]?

    public init(
        denseBooleanMap: [Swift.String: Swift.Bool]? = nil,
        denseNumberMap: [Swift.String: Swift.Int]? = nil,
        denseStringMap: [Swift.String: Swift.String]? = nil,
        denseStructMap: [Swift.String: ExampleClientTypes.GreetingStruct]? = nil,
        sparseBooleanMap: [Swift.String: Swift.Bool?]? = nil,
        sparseNumberMap: [Swift.String: Swift.Int?]? = nil,
        sparseStringMap: [Swift.String: Swift.String?]? = nil,
        sparseStructMap: [Swift.String: ExampleClientTypes.GreetingStruct?]? = nil
    ) {
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
"""
        jsonMapsOutput.shouldContain(expectedJsonMapsOutput)
    }

    @Test
    fun `deprecated trait on structure`() {
        val model = javaClass.classLoader.getResource("deprecated-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        var structWithDeprecatedTrait =
            manifest
                .getFileString("Sources/example/models/StructWithDeprecatedTrait.swift")
                .get()
        Assertions.assertNotNull(structWithDeprecatedTrait)
        var structContainsDeprecatedTrait = """
extension ExampleClientTypes {

    @available(*, deprecated, message: "This shape is no longer used. API deprecated since 1.3")
    public struct StructWithDeprecatedTrait: Swift.Sendable {
"""
        structWithDeprecatedTrait.shouldContain(structContainsDeprecatedTrait)

        structWithDeprecatedTrait =
            manifest
                .getFileString("Sources/example/models/StructSincePropertySet.swift")
                .get()
        Assertions.assertNotNull(structWithDeprecatedTrait)
        structContainsDeprecatedTrait = """
extension ExampleClientTypes {

    @available(*, deprecated, message: "API deprecated since 2019-03-21")
    public struct StructSincePropertySet: Swift.Sendable {
"""
        structWithDeprecatedTrait.shouldContain(structContainsDeprecatedTrait)
    }

    @Test
    fun `deprecated trait on synthetically cloned structure and structure member`() {
        val model = javaClass.classLoader.getResource("deprecated-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val structWithDeprecatedTraitMember =
            manifest
                .getFileString("Sources/example/models/OperationWithDeprecatedTraitInput.swift")
                .get()
        Assertions.assertNotNull(structWithDeprecatedTraitMember)
        val structContainsDeprecatedMember = """
@available(*, deprecated, message: "This shape is no longer used. API deprecated since 1.3")
public struct OperationWithDeprecatedTraitInput: Swift.Sendable {
    public var bool: Swift.Bool?
    public var foo: ExampleClientTypes.Foo?
    public var intVal: Swift.Int?
    @available(*, deprecated)
    public var string: Swift.String?
    @available(*, deprecated, message: "API deprecated since 2019-03-21")
    public var structSincePropertySet: ExampleClientTypes.StructSincePropertySet?
    @available(*, deprecated, message: "This shape is no longer used. API deprecated since 1.3")
    public var structWithDeprecatedTrait: ExampleClientTypes.StructWithDeprecatedTrait?
"""
        structWithDeprecatedTraitMember.shouldContain(structContainsDeprecatedMember)
    }

    @Test
    fun `deprecated trait fetched from the target of a struct member`() {
        val model = javaClass.classLoader.getResource("deprecated-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val structWithDeprecatedTraitMember =
            manifest
                .getFileString("Sources/example/models/Foo.swift")
                .get()
        Assertions.assertNotNull(structWithDeprecatedTraitMember)
        val structContainsDeprecatedMember = """
extension ExampleClientTypes {

    public struct Foo: Swift.Sendable {
        /// Test documentation with deprecated
        @available(*, deprecated)
        public var baz: Swift.String?
        /// Test documentation with deprecated
        public var qux: Swift.String?
"""
        structWithDeprecatedTraitMember.shouldContain(structContainsDeprecatedMember)
    }
}
