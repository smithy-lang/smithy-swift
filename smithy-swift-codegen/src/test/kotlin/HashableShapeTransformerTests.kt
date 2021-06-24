import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.HashableShapeTransformer
import software.amazon.smithy.swift.codegen.HashableTrait
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.model.hasTrait
import kotlin.streams.toList

class HashableShapeTransformerTests {

    @Test
    fun `leave non-hashable models unchanged`() {
        val model = javaClass.getResource("simple-service-with-operation-and-dependency.smithy").asSmithy()
        val transformed = HashableShapeTransformer.transform(model)
        transformed.shapes().toList().forEach {
            Assertions.assertFalse(transformed.getShape(it.id).get().hasTrait<HashableTrait>())
        }
    }

    @Test
    fun `add the hashable trait to hashable shapes`() {
        val model = javaClass.getResource("hashable-trait-test.smithy").asSmithy()
        val transformed = HashableShapeTransformer.transform(model)

        val traitedMember = "smithy.example#HashableStructure"
        val traitedMemberShape = transformed.getShape(ShapeId.from(traitedMember)).get()
        Assertions.assertTrue(traitedMemberShape.hasTrait<HashableTrait>())

        val traitedMember2 = "smithy.example#NestedHashableStructure"
        val traitedMemberShape2 = transformed.getShape(ShapeId.from(traitedMember2)).get()
        Assertions.assertTrue(traitedMemberShape2.hasTrait<HashableTrait>())

        val untraitedMember = "smithy.example#HashableInput"
        val untraitedMemberShape = transformed.getShape(ShapeId.from(untraitedMember)).get()
        Assertions.assertFalse(untraitedMemberShape.hasTrait<HashableTrait>())
    }

    @Test
    fun `add the hashable trait to hashable shapes during integration with SwiftCodegenPlugin`() {
        val model = javaClass.getResource("hashable-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val hashableShapeInput = manifest
            .getFileString("example/models/HashableShapesInput.swift").get()
        Assertions.assertNotNull(hashableShapeInput)
        val expected = """
            public struct HashableShapesInput: Equatable {
                public let `set`: Set<HashableStructure>?
                public let bar: String?
            
                public init (
                    `set`: Set<HashableStructure>? = nil,
                    bar: String? = nil
                )
                {
                    self.`set` = `set`
                    self.bar = bar
                }
            }
        """.trimIndent()
        hashableShapeInput.shouldContain(expected)

        val hashableShapeOutput = manifest
            .getFileString("example/models/HashableShapesOutputResponse.swift").get()
        Assertions.assertNotNull(hashableShapeOutput)
        val expectedOutput = """
            public struct HashableShapesOutputResponse: Equatable {
                public let quz: String?
            
                public init (
                    quz: String? = nil
                )
                {
                    self.quz = quz
                }
            }
        """.trimIndent()
        hashableShapeOutput.shouldContain(expectedOutput)

        val hashableSetShape = manifest
            .getFileString("example/models/HashableStructure.swift").get()
        Assertions.assertNotNull(hashableSetShape)
        val expectedStructureShape = """
            public struct HashableStructure: Equatable, Hashable {
                public let baz: NestedHashableStructure?
                public let foo: String?
            
                public init (
                    baz: NestedHashableStructure? = nil,
                    foo: String? = nil
                )
                {
                    self.baz = baz
                    self.foo = foo
                }
            }
        """.trimIndent()
        hashableSetShape.shouldContain(expectedStructureShape)

        val hashableNestedStructure = manifest
            .getFileString("example/models/NestedHashableStructure.swift").get()
        Assertions.assertNotNull(hashableNestedStructure)
        val expectedNestedStructureShape = """
            public struct NestedHashableStructure: Equatable, Hashable {
                public let bar: String?
                public let quz: Int?
            
                public init (
                    bar: String? = nil,
                    quz: Int? = nil
                )
                {
                    self.bar = bar
                    self.quz = quz
                }
            }
        """.trimIndent()
        hashableNestedStructure.shouldContain(expectedNestedStructureShape)
    }
}
