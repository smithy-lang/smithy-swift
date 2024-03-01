/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import org.junit.jupiter.api.Assertions
import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.DocumentationTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.HttpErrorTrait
import software.amazon.smithy.model.traits.RetryableTrait
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.customtraits.SwiftBoxTrait
import software.amazon.smithy.swift.codegen.integration.HttpBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.AddOperationShapes
import software.amazon.smithy.swift.codegen.model.NestedShapeTransformer
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import java.net.URL

/**
 * Load and initialize a model from a String (from smithy-rs)
 */
private const val SmithyVersion = "1.0"
fun String.asSmithyModel(sourceLocation: String? = null): Model {
    val processed = letIf(!this.startsWith("\$version")) { "\$version: ${SmithyVersion.doubleQuote()}\n$it" }
    return Model.assembler().discoverModels().addUnparsedModel(sourceLocation ?: "test.smithy", processed).assemble().unwrap()
}

fun String.doubleQuote(): String = "\"${this.slashEscape('\\').slashEscape('"')}\""
fun String.slashEscape(char: Char) = this.replace(char.toString(), """\$char""")
fun <T> T.letIf(cond: Boolean, f: (T) -> T): T {
    return if (cond) {
        f(this)
    } else this
}

fun createSymbolProvider(): SymbolProvider? {
    return SymbolProvider { shape: Shape ->
        Symbol.builder()
            .name(shape.id.name)
            .namespace(shape.id.namespace, "/")
            .definitionFile(shape.id.name + ".txt")
            .build()
    }
}

/**
 * Load and initialize a model from a Java resource URL
 */
fun URL.asSmithy(): Model =
    Model.assembler()
        .addImport(this)
        .discoverModels()
        .assemble()
        .unwrap()

fun createModelFromShapes(vararg shapes: Shape): Model {
    return Model.assembler()
        .addShapes(*shapes)
        .assemble()
        .unwrap()
}

fun buildPluginContext(
    model: Model,
    manifest: FileManifest,
    serviceShapeId: String,
    moduleName: String,
    moduleVersion: String
): PluginContext {
    return PluginContext.builder()
        .model(model)
        .fileManifest(manifest)
        .settings(getSettingsNode(serviceShapeId, moduleName, moduleVersion))
        .build()
}

fun buildMockPluginContext(model: Model, manifest: FileManifest, serviceShapeId: String = "com.test#Example"): PluginContext {
    return buildPluginContext(model, manifest, serviceShapeId, "example", "0.0.1")
}

fun createModelWithStructureWithoutErrorTrait(): Model {
    return """
        namespace smithy.example
        /// This is documentation about the shape.
        structure MyStruct {
          foo: String,
          bar: PrimitiveInteger,
          /// This is documentation about the member.
          baz: Integer,
        }
    """.asSmithyModel()
}

/**
 * This function produces a smithy model like:
structure RecursiveShapesInputOutput {
nested: RecursiveShapesInputOutputNested1
}

structure RecursiveShapesInputOutputNested1 {
foo: String,
nested: RecursiveShapesInputOutputNested2
}

structure RecursiveShapesInputOutputNested2 {
bar: String,
recursiveMember: RecursiveShapesInputOutputNested1,
}
 */
fun createStructureContainingNestedRecursiveShape(): List<StructureShape> {
    val shapes = mutableListOf<StructureShape>()
    val memberFoo =
        MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested1\$foo").target("smithy.api#String")
            .build()
    var memberNested = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested1\$nested")
        .target("smithy.example#RecursiveShapesInputOutputNested2").build()
    memberNested = memberNested.toBuilder().addTrait(SwiftBoxTrait()).build()

    val recursiveShapeNested1 = StructureShape.builder()
        .id("smithy.example#RecursiveShapesInputOutputNested1")
        .addMember(memberFoo)
        .addMember(memberNested)
        .build()
    val memberRecursiveMember =
        MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested2\$recursiveMember")
            .target("smithy.example#RecursiveShapesInputOutputNested1").build()
    val memberBar =
        MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested2\$bar").target("smithy.api#String")
            .build()

    val recursiveShapeNested2 = StructureShape.builder()
        .id("smithy.example#RecursiveShapesInputOutputNested2")
        .addMember(memberRecursiveMember)
        .addMember(memberBar)
        .build()

    val member1 = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutput\$nested")
        .target("smithy.example#RecursiveShapesInputOutputNested1").build()

    val topLevelShape = StructureShape.builder()
        .id("smithy.example#RecursiveShapesInputOutput")
        .addMember(member1)
        .addTrait(DocumentationTrait("This *is* documentation about the shape."))
        .build()
    shapes.add(recursiveShapeNested1)
    shapes.add(recursiveShapeNested2)
    shapes.add(topLevelShape)
    return shapes
}

/**
 * This function produces a smithy model like:
structure RecursiveShapesInputOutput {
nested: RecursiveShapesInputOutputNested1
}

structure RecursiveShapesInputOutputNested1 {
foo: String,
nested: RecursiveShapesInputOutputNested2
}

list RecursiveList {
member: RecursiveShapesInputOutputNested1
}

structure RecursiveShapesInputOutputNested2 {
bar: String,
recursiveList: RecursiveList,
}
 */
fun createStructureContainingNestedRecursiveShapeList(): List<StructureShape> {
    val shapes = mutableListOf<StructureShape>()

    val memberRecursiveMember =
        MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested2\$recursiveMember")
            .target("smithy.example#RecursiveShapesInputOutputNested1").build()
    val memberBar =
        MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNested2\$bar").target("smithy.api#String")
            .build()

    val recursiveShapeNested2 = StructureShape.builder()
        .id("smithy.example#RecursiveShapesInputOutputNested2")
        .addMember(memberRecursiveMember)
        .addMember(memberBar)
        .build()

    val memberRecursiveList = MemberShape.builder().id("smithy.example#RecursiveList\$member")
        .target("smithy.example#RecursiveShapesInputOutputNested1").build()

    val listShape = ListShape.builder()
        .id("smithy.example#RecursiveList")
        .addMember(memberRecursiveList)

    val memberFoo = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNestedList1\$foo")
        .target("smithy.api#String").build()
    val memberNested = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputNestedList1\$recursiveList")
        .target("smithy.example#RecursiveList").build()
    val recursiveShapeNested1 = StructureShape.builder()
        .id("smithy.example#RecursiveShapesInputOutputNestedList1")
        .addMember(memberFoo)
        .addMember(memberNested)
        .build()

    val member1 = MemberShape.builder().id("smithy.example#RecursiveShapesInputOutputLists\$nested")
        .target("smithy.example#RecursiveShapesInputOutputNested1").build()

    val topLevelShape = StructureShape.builder()
        .id("smithy.example#RecursiveShapesInputOutputLists")
        .addMember(member1)
        .addTrait(DocumentationTrait("This *is* documentation about the shape."))
        .build()
    shapes.add(recursiveShapeNested1)
    shapes.add(recursiveShapeNested2)
    shapes.add(topLevelShape)
    return shapes
}

fun createStructureWithOptionalErrorMessage(): StructureShape {
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

class TestContext(
    val generationCtx: ProtocolGenerator.GenerationContext,
    val manifest: MockManifest,
    val generator: ProtocolGenerator
) {
    companion object {
        fun initContextFrom(
            smithyFile: String,
            serviceShapeId: String,
            httpBindingProtocolGenerator: HttpBindingProtocolGenerator? = null,
            swiftSettingCallback: ((model: Model) -> SwiftSettings)? = null
        ): TestContext {
            return initContextFrom(listOf(smithyFile), serviceShapeId, httpBindingProtocolGenerator, swiftSettingCallback)
        }
        fun initContextFrom(
            smithyFiles: List<String>,
            serviceShapeId: String,
            httpBindingProtocolGenerator: HttpBindingProtocolGenerator? = null,
            swiftSettingCallback: ((model: Model) -> SwiftSettings)? = null,
            integrations: List<SwiftIntegration> = emptyList()
        ): TestContext {

            var modelAssembler = Model.assembler()
            for (smithyFile in smithyFiles) {
                modelAssembler.addImport(javaClass.getResource(smithyFile))
            }
            var model = modelAssembler
                .discoverModels()
                .assemble()
                .unwrap()

            val manifest = MockManifest()
            val swiftSettings = if (swiftSettingCallback == null) model.defaultSettings() else swiftSettingCallback(model)

            val pluginContext = buildPluginContext(model, manifest, serviceShapeId, swiftSettings.moduleName, swiftSettings.moduleVersion)
            SwiftCodegenPlugin().execute(pluginContext)

            model = AddOperationShapes.execute(model, swiftSettings.getService(model), swiftSettings.moduleName)
            model = RecursiveShapeBoxer.transform(model)
            model = NestedShapeTransformer.transform(model, swiftSettings.getService(model))
            val protocolGenerator = httpBindingProtocolGenerator ?: MockHttpRestJsonProtocolGenerator()
            return model.newTestContext(manifest, serviceShapeId, swiftSettings, protocolGenerator, integrations)
        }
    }
}

// Convenience function to retrieve a shape from a [TestContext]
fun TestContext.expectShape(shapeId: String): Shape =
    this.generationCtx.model.expectShape(ShapeId.from(shapeId))

fun Model.newTestContext(
    serviceShapeId: String = "com.test#Example",
    settings: SwiftSettings = this.defaultSettings(),
    generator: ProtocolGenerator = MockHttpRestJsonProtocolGenerator()
): TestContext {
    return newTestContext(MockManifest(), serviceShapeId, settings, generator)
}

fun Model.newTestContext(
    manifest: MockManifest,
    serviceShapeId: String,
    settings: SwiftSettings,
    generator: ProtocolGenerator,
    integrations: List<SwiftIntegration> = emptyList()
): TestContext {
    val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(this, settings)
    val service = this.getShape(ShapeId.from(serviceShapeId)).get().asServiceShape().get()
    val delegator = SwiftDelegator(settings, this, manifest, provider)

    val ctx = ProtocolGenerator.GenerationContext(
        settings,
        this,
        service,
        provider,
        integrations,
        generator.protocol,
        delegator
    )
    return TestContext(ctx, manifest, generator)
}

fun getSettingsNode(
    serviceShapeId: String = "com.test#Example",
    moduleName: String = "example",
    moduleVersion: String = "1.0.0",
    sdkId: String = "Example"
): ObjectNode {
    return Node.objectNodeBuilder()
        .withMember("service", Node.from(serviceShapeId))
        .withMember("module", Node.from(moduleName))
        .withMember("moduleVersion", Node.from(moduleVersion))
        .withMember("homepage", Node.from("https://docs.amplify.aws/"))
        .withMember("sdkId", Node.from(sdkId))
        .withMember("author", Node.from("Amazon Web Services"))
        .withMember("gitRepo", Node.from("https://github.com/aws-amplify/amplify-codegen.git"))
        .withMember("swiftVersion", Node.from("5.5.0"))
        .build()
}

fun Model.defaultSettings(
    serviceShapeId: String = "com.test#Example",
    moduleName: String = "example",
    moduleVersion: String = "1.0.0",
    sdkId: String = "Example"
): SwiftSettings =
    SwiftSettings.from(
        this,
        getSettingsNode(serviceShapeId, moduleName, moduleVersion, sdkId)
    )

fun getModelFileContents(namespace: String, filename: String, manifest: MockManifest): String {
    return getFileContents(manifest, "$namespace/models/$filename")
}

fun getTestFileContents(namespace: String, filename: String, manifest: MockManifest): String {
    return getFileContents(manifest, "${namespace}Tests/$filename")
}

fun getFileContents(manifest: MockManifest, fileName: String): String {
    return manifest.expectFileString(fileName)
}

fun listFilesFromManifest(manifest: MockManifest): String {
    var listFiles = StringBuilder()
    for (file in manifest.files) {
        listFiles.append("${file}\n")
    }
    return listFiles.toString()
}

fun String.shouldSyntacticSanityCheck() {
    // sanity check the generated code for matching paranthesis
    var openBraces = 0
    var closedBraces = 0
    var openParens = 0
    var closedParens = 0
    this.forEach {
        when (it) {
            '{' -> openBraces++
            '}' -> closedBraces++
            '(' -> openParens++
            ')' -> closedParens++
        }
    }
    Assertions.assertEquals(openBraces, closedBraces, "unmatched open/closed braces:\n$this")
    Assertions.assertEquals(openParens, closedParens, "unmatched open/close parens:\n$this")
}
