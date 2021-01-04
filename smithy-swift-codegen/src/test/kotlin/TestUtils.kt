/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import java.net.URL
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
import software.amazon.smithy.swift.codegen.SwiftBoxTrait
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

/**
 * Load and initialize a model from a String (from smithy-rs)
 */
private const val SmithyVersion = "1.0"
fun String.asSmithyModel(sourceLocation: String? = null): Model {
    val processed = letIf(!this.startsWith("\$version")) { "\$version: ${SmithyVersion.doubleQuote()}\n$it" }
    return Model.assembler().discoverModels().addUnparsedModel("$sourceLocation", processed).assemble().unwrap()
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

fun createStructureWithoutErrorTrait(): StructureShape {
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

/**
 * Container for type instances necessary for tests
 */
data class TestContext(
    val generationCtx: ProtocolGenerator.GenerationContext,
    val manifest: MockManifest,
    val generator: ProtocolGenerator
)

// Convenience function to retrieve a shape from a [TestContext]
fun TestContext.expectShape(shapeId: String): Shape =
    this.generationCtx.model.expectShape(ShapeId.from(shapeId))

/**
 * Initiate codegen for the model and produce a [TestContext].
 *
 * @param serviceShapeId the smithy Id for the service to codegen, defaults to "com.test#Example"
 */
fun Model.newTestContext(
    serviceShapeId: String = "com.test#Example",
    settings: SwiftSettings = this.defaultSettings(),
    generator: ProtocolGenerator = MockHttpProtocolGenerator()
): TestContext {
    val manifest = MockManifest()
    val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(this, serviceShapeId.split("#")[1])
    val service = this.getShape(ShapeId.from(serviceShapeId)).get().asServiceShape().get()
    val delegator = SwiftDelegator(settings, this, manifest, provider)

    val ctx = ProtocolGenerator.GenerationContext(
        settings,
        this,
        service,
        provider,
        listOf(),
        generator.protocol,
        delegator
    )
    return TestContext(ctx, manifest, generator)
}

fun getSettingsNode(
    serviceShapeId: String = "com.test#Example",
    moduleName: String = "example",
    moduleVersion: String = "1.0.0"
): ObjectNode {
    return Node.objectNodeBuilder()
        .withMember("service", Node.from(serviceShapeId))
        .withMember("module", Node.from(moduleName))
        .withMember("moduleVersion", Node.from(moduleVersion))
        .withMember("homepage", Node.from("https://docs.amplify.aws/"))
        .withMember("author", Node.from("Amazon Web Services"))
        .withMember("gitRepo", Node.from("https://github.com/aws-amplify/amplify-codegen.git"))
        .withMember("swiftVersion", Node.from("5.1.0"))
        .build()
}

fun Model.defaultSettings(
    serviceShapeId: String = "com.test#Example",
    moduleName: String = "example",
    moduleVersion: String = "1.0.0"
): SwiftSettings =
    SwiftSettings.from(
        this,
        getSettingsNode(serviceShapeId, moduleName, moduleVersion)
    )

fun getModelFileContents(namespace: String, filename: String, manifest: MockManifest): String {
    return manifest.expectFileString("$namespace/models/$filename")
}

fun getTestFileContents(namespace: String, filename: String, manifest: MockManifest): String {
    return manifest.expectFileString("${namespace}Tests/$filename")
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
