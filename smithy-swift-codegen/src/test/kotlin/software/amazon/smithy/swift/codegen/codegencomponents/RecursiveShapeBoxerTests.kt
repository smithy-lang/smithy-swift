package software.amazon.smithy.swift.codegen.codegencomponents

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.asSmithy
import software.amazon.smithy.swift.codegen.buildMockPluginContext
import software.amazon.smithy.swift.codegen.customtraits.SwiftBoxTrait
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer

internal class RecursiveShapeBoxerTests {
    @Test
    fun `leave non-recursive models unchanged`() {
        val model = javaClass.classLoader.getResource("simple-service-with-operation-and-dependency.smithy").asSmithy()
        val transformed = RecursiveShapeBoxer.transform(model)
        transformed.shapes().toList().forEach {
            Assertions.assertFalse(transformed.getShape(it.id).get().hasTrait(SwiftBoxTrait::class.java))
        }
    }

    @Test
    fun `add the box trait to recursive shapes`() {
        val model = javaClass.classLoader.getResource("recursive-shape-test.smithy").asSmithy()
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
        val model = javaClass.classLoader.getResource("recursive-shape-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)

        val recursiveShapesInput =
            manifest
                .getFileString("Sources/example/models/RecursiveShapesInput.swift")
                .get()
        Assertions.assertNotNull(recursiveShapesInput)
        val expected = """
public struct RecursiveShapesInput: Swift.Sendable {
    public var nested: ExampleClientTypes.RecursiveShapesInputOutputNested1?

    public init(
        nested: ExampleClientTypes.RecursiveShapesInputOutputNested1? = nil
    ) {
        self.nested = nested
    }
}
"""
        recursiveShapesInput.shouldContain(expected)

        val recursiveShapesOutput =
            manifest
                .getFileString("Sources/example/models/RecursiveShapesOutput.swift")
                .get()
        Assertions.assertNotNull(recursiveShapesOutput)
        val expected2 = """
public struct RecursiveShapesOutput: Swift.Sendable {
    public var nested: ExampleClientTypes.RecursiveShapesInputOutputNested1?

    public init(
        nested: ExampleClientTypes.RecursiveShapesInputOutputNested1? = nil
    ) {
        self.nested = nested
    }
}
"""
        recursiveShapesOutput.shouldContain(expected2)

        val recursiveShapesInputOutputNested1 =
            manifest
                .getFileString("Sources/example/models/RecursiveShapesInputOutputNested1.swift")
                .get()
        Assertions.assertNotNull(recursiveShapesInputOutputNested1)
        val expected3 = """
extension ExampleClientTypes {

    public struct RecursiveShapesInputOutputNested1: Swift.Sendable {
        public var foo: Swift.String?
        @Indirect public var nested: ExampleClientTypes.RecursiveShapesInputOutputNested2?

        public init(
            foo: Swift.String? = nil,
            nested: ExampleClientTypes.RecursiveShapesInputOutputNested2? = nil
        ) {
            self.foo = foo
            self.nested = nested
        }
    }
}
"""
        recursiveShapesInputOutputNested1.shouldContain(expected3)

        val recursiveShapesInputOutputNested2 =
            manifest
                .getFileString("Sources/example/models/RecursiveShapesInputOutputNested2.swift")
                .get()
        Assertions.assertNotNull(recursiveShapesInputOutputNested2)
        val expected4 = """
    public struct RecursiveShapesInputOutputNested2: Swift.Sendable {
        public var bar: Swift.String?
        public var recursiveMember: ExampleClientTypes.RecursiveShapesInputOutputNested1?

        public init(
            bar: Swift.String? = nil,
            recursiveMember: ExampleClientTypes.RecursiveShapesInputOutputNested1? = nil
        ) {
            self.bar = bar
            self.recursiveMember = recursiveMember
        }
    }
}
"""
        recursiveShapesInputOutputNested2.shouldContain(expected4)
    }
}
