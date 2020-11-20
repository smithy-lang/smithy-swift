package software.amazon.smithy.swift.codegen

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
    fun `add the box trait to during integration with SwiftCodegenPlugin`() {
        val model = createModelFromSmithy("recursive-shape-test.smithy")
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest)
        SwiftCodegenPlugin().execute(context)
        val x = 1
    }
}
