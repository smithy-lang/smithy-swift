package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContain
import kotlin.streams.toList
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.model.shapes.ShapeId

internal class RecursiveShapeBoxerTests : TestsBase() {
    @Test
    fun `leave non-recursive models unchanged`() {
        val model = createModelFromSmithy("simple-service-with-operation-and-dependency.smithy")
        val transformed = RecursiveShapeBoxer.transform(model)
        transformed.shapes().toList().forEach {
            Assertions.assertFalse(transformed.getShape(it.id).get().hasTrait(SwiftBoxTrait::class.java))
        }
    }

    @Test
    fun `add the box trait to recursive shapes`() {
        val model = createModelFromSmithy("recursive-shape-test.smithy")
        val transformed = RecursiveShapeBoxer.transform(model)

        val traitedMember = "smithy.example#RecursiveShapesInputOutputNested1\$nested"
        val traitedMemberShape = transformed.getShape(ShapeId.from(traitedMember)).get()
        Assertions.assertTrue(traitedMemberShape.hasTrait(SwiftBoxTrait::class.java))

        val unTraitedMember = "smithy.example#RecursiveShapesInputOutputNested2\$recursiveMember"
        val unTraitedMemberShape = transformed.getShape(ShapeId.from(unTraitedMember)).get()
        Assertions.assertFalse(unTraitedMemberShape.hasTrait(SwiftBoxTrait::class.java))
    }

    @Test
    fun `add the box trait to recursive shapes during integration with SwiftCodegenPlugin`() {
        val model = createModelFromSmithy("recursive-shape-test.smithy")
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)
        SwiftCodegenPlugin().execute(context)

        val recursiveShapesInput = manifest
                .getFileString("example/models/RecursiveShapesInput.swift").get()
        Assertions.assertNotNull(recursiveShapesInput)
        recursiveShapesInput.shouldContain(
                "public struct RecursiveShapesInput: Equatable {\n" +
                        "    public let nested: RecursiveShapesInputOutputNested1?\n" +
                        "\n" +
                        "    public init (\n" +
                        "        nested: RecursiveShapesInputOutputNested1? = nil\n" +
                        "    )\n" +
                        "    {\n" +
                        "        self.nested = nested\n" +
                        "    }\n" +
                        "}"
        )

        val recursiveShapesOutput = manifest
                .getFileString("example/models/RecursiveShapesOutput.swift").get()
        Assertions.assertNotNull(recursiveShapesOutput)
        recursiveShapesOutput.shouldContain(
                "public struct RecursiveShapesOutput: Equatable {\n" +
                        "    public let nested: RecursiveShapesInputOutputNested1?\n" +
                        "\n" +
                        "    public init (\n" +
                        "        nested: RecursiveShapesInputOutputNested1? = nil\n" +
                        "    )\n" +
                        "    {\n" +
                        "        self.nested = nested\n" +
                        "    }\n" +
                        "}"
        )

        val recursiveShapesInputOutputNested1 = manifest
                .getFileString("example/models/RecursiveShapesInputOutputNested1.swift").get()
        Assertions.assertNotNull(recursiveShapesInputOutputNested1)
        recursiveShapesInputOutputNested1.shouldContain(
                "public struct RecursiveShapesInputOutputNested1: Equatable {\n" +
                        "    public let foo: String?\n" +
                        "    public let nested: Box<RecursiveShapesInputOutputNested2>?\n" +
                        "\n" +
                        "    public init (\n" +
                        "        foo: String? = nil,\n" +
                        "        nested: Box<RecursiveShapesInputOutputNested2>? = nil\n" +
                        "    )\n" +
                        "    {\n" +
                        "        self.foo = foo\n" +
                        "        self.nested = nested\n" +
                        "    }\n" +
                        "}"
        )

        val recursiveShapesInputOutputNested2 = manifest
                .getFileString("example/models/RecursiveShapesInputOutputNested2.swift").get()
        Assertions.assertNotNull(recursiveShapesInputOutputNested2)
        recursiveShapesInputOutputNested2.shouldContain(
                "public struct RecursiveShapesInputOutputNested2: Equatable {\n" +
                        "    public let bar: String?\n" +
                        "    public let recursiveMember: RecursiveShapesInputOutputNested1?\n" +
                        "\n" +
                        "    public init (\n" +
                        "        bar: String? = nil,\n" +
                        "        recursiveMember: RecursiveShapesInputOutputNested1? = nil\n" +
                        "    )\n" +
                        "    {\n" +
                        "        self.bar = bar\n" +
                        "        self.recursiveMember = recursiveMember\n" +
                        "    }\n" +
                        "}"
        )
    }
}
