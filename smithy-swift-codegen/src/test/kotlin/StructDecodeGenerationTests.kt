/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes
import software.amazon.smithy.swift.codegen.model.NeedsReaderWriterTransformer
import software.amazon.smithy.swift.codegen.model.NestedShapeTransformer
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer

class StructDecodeGenerationTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        model = RecursiveShapeBoxer.transform(model)
        model = NestedShapeTransformer.transform(model, settings.getService(model))
        model = NeedsReaderWriterTransformer.transform(model, settings.getService(model))
        return model.newTestContext()
    }
    val newTestContext = newTestContext()

    init {
        newTestContext.generator.generateDeserializers(newTestContext.generationCtx)
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates decodable conformance for nested structures`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested+ReadWrite.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested2+ReadWrite.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested3+ReadWrite.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested4+ReadWrite.swift"))
    }

    @Test
    fun `it decodes nested documents with aggregate shapes`() {
        val contents = getModelFileContents("example", "Nested4+ReadWrite.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension ExampleClientTypes.Nested4 {

    static func write(value: ExampleClientTypes.Nested4?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["intList"].writeList(value.intList, memberWritingClosure: Swift.Int.write(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["intMap"].writeMap(value.intMap, valueWritingClosure: Swift.Int.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["member1"].write(value.member1)
        try writer["stringMap"].writeMap(value.stringMap, valueWritingClosure: listWritingClosure(memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }

    static func read(from reader: SmithyJSON.Reader) throws -> ExampleClientTypes.Nested4 {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = ExampleClientTypes.Nested4()
        value.member1 = try reader["member1"].readIfPresent()
        value.intList = try reader["intList"].readListIfPresent(memberReadingClosure: Swift.Int.read(from:), memberNodeInfo: "member", isFlattened: false)
        value.intMap = try reader["intMap"].readMapIfPresent(valueReadingClosure: Swift.Int.read(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        value.stringMap = try reader["stringMap"].readMapIfPresent(valueReadingClosure: listReadingClosure(memberReadingClosure: Swift.String.read(from:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it decodes recursive boxed types correctly`() {
        val contents = getModelFileContents(
            "example",
            "RecursiveShapesInputOutputNested1+ReadWrite.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension ExampleClientTypes.RecursiveShapesInputOutputNested1 {

    static func write(value: ExampleClientTypes.RecursiveShapesInputOutputNested1?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["foo"].write(value.foo)
        try writer["nested"].write(value.nested, with: ExampleClientTypes.RecursiveShapesInputOutputNested2.write(value:to:))
    }

    static func read(from reader: SmithyJSON.Reader) throws -> ExampleClientTypes.RecursiveShapesInputOutputNested1 {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = ExampleClientTypes.RecursiveShapesInputOutputNested1()
        value.foo = try reader["foo"].readIfPresent()
        value.nested = try reader["nested"].readIfPresent(with: ExampleClientTypes.RecursiveShapesInputOutputNested2.read(from:))
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes one side of the recursive shape`() {
        val contents = getModelFileContents(
            "example",
            "RecursiveShapesInputOutputNested2+ReadWrite.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension ExampleClientTypes.RecursiveShapesInputOutputNested2 {

    static func write(value: ExampleClientTypes.RecursiveShapesInputOutputNested2?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["bar"].write(value.bar)
        try writer["recursiveMember"].write(value.recursiveMember, with: ExampleClientTypes.RecursiveShapesInputOutputNested1.write(value:to:))
    }

    static func read(from reader: SmithyJSON.Reader) throws -> ExampleClientTypes.RecursiveShapesInputOutputNested2 {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = ExampleClientTypes.RecursiveShapesInputOutputNested2()
        value.bar = try reader["bar"].readIfPresent()
        value.recursiveMember = try reader["recursiveMember"].readIfPresent(with: ExampleClientTypes.RecursiveShapesInputOutputNested1.read(from:))
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
