package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.StructureShape
import java.util.function.Consumer

class StructureGeneratorTests: TestsBase() {
    @Test
    fun `it renders structures`() {

        val struct: StructureShape = createStructureWithoutErrorTrait()
        val model: Model = createModelWithStructureShape(struct = struct)
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "test")
        val writer = SwiftWriter("MockPackage")
        val generator = StructureGenerator(model, provider, writer, struct)
        generator.render()

        val contents = writer.toString()

        contents.shouldContain(SwiftWriter.staticHeader)

        val expectedGeneratedStructure = """
public struct MyStruct {
    public let bar: Int = 0
    public let baz: Int? = nil
    public let foo: String? = nil
}
"""

        contents.shouldContain(expectedGeneratedStructure)
    }

    private fun createStructureWithoutErrorTrait(): StructureShape {
        val member1 = MemberShape.builder().id("smithy.example#MyStruct\$foo").target("smithy.api#String").build()
        val member2 = MemberShape.builder().id("smithy.example#MyStruct\$bar").target("smithy.api#PrimitiveInteger").build()
        val member3 = MemberShape.builder().id("smithy.example#MyStruct\$baz").target("smithy.api#Integer").build()

        return StructureShape.builder()
            .id("smithy.example#MyStruct")
            .addMember(member1)
            .addMember(member2)
            .addMember(member3)
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
