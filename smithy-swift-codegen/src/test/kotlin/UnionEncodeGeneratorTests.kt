/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.model.AddOperationShapes
import software.amazon.smithy.swift.codegen.model.NestedShapeTransformer
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer

class UnionEncodeGeneratorTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        model = preprocessModel(model)
        return model.newTestContext()
    }
    private fun preprocessModel(model: Model): Model {
        val settings = model.defaultSettings()
        var resolvedModel = model
        resolvedModel = AddOperationShapes.execute(resolvedModel, settings.getService(resolvedModel), settings.moduleName)
        resolvedModel = RecursiveShapeBoxer.transform(resolvedModel)
        resolvedModel = NestedShapeTransformer.transform(resolvedModel, settings.getService(resolvedModel))
        return resolvedModel
    }
    val newTestContext = newTestContext()
    init {
        newTestContext.generator.generateSerializers(newTestContext.generationCtx)
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates encodable conformance in correct file`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/JsonUnionsInput+Write.swift"))
    }

    @Test
    fun `it creates encodable conformance for nested structures`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/MyUnion+ReadWrite.swift"))
    }

    @Test
    fun `it encodes a union member in an operation`() {
        val contents = getModelFileContents("example", "JsonUnionsInput+Write.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension JsonUnionsInput {

    static func write(value: JsonUnionsInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["contents"].write(value.contents, writingClosure: ExampleClientTypes.MyUnion.write(value:to:))
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes a union with various member shape types`() {
        val contents = getModelFileContents("example", "MyUnion+ReadWrite.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension ExampleClientTypes.MyUnion {

    static func write(value: ExampleClientTypes.MyUnion?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        switch value {
            case let .blobvalue(blobvalue):
                try writer["blobValue"].write(blobvalue)
            case let .booleanvalue(booleanvalue):
                try writer["booleanValue"].write(booleanvalue)
            case let .enumvalue(enumvalue):
                try writer["enumValue"].write(enumvalue)
            case let .inheritedtimestamp(inheritedtimestamp):
                try writer["inheritedTimestamp"].writeTimestamp(inheritedtimestamp, format: .httpDate)
            case let .listvalue(listvalue):
                try writer["listValue"].writeList(listvalue, memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "member", isFlattened: false)
            case let .mapvalue(mapvalue):
                try writer["mapValue"].writeMap(mapvalue, valueWritingClosure: Swift.String.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
            case let .numbervalue(numbervalue):
                try writer["numberValue"].write(numbervalue)
            case let .stringvalue(stringvalue):
                try writer["stringValue"].write(stringvalue)
            case let .structurevalue(structurevalue):
                try writer["structureValue"].write(structurevalue, writingClosure: ExampleClientTypes.GreetingWithErrorsOutput.write(value:to:))
            case let .timestampvalue(timestampvalue):
                try writer["timestampValue"].writeTimestamp(timestampvalue, format: .epochSeconds)
            case let .sdkUnknown(sdkUnknown):
                try writer["sdkUnknown"].write(sdkUnknown)
        }
    }

    static func read(from reader: SmithyJSON.Reader) throws -> ExampleClientTypes.MyUnion {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        let name = reader.children.filter { ${'$'}0.hasContent }.first { ${'$'}0.nodeInfo.name != "__type" }?.nodeInfo.name
        switch name {
            case "stringValue":
                return .stringvalue(try reader["stringValue"].read())
            case "booleanValue":
                return .booleanvalue(try reader["booleanValue"].read())
            case "numberValue":
                return .numbervalue(try reader["numberValue"].read())
            case "blobValue":
                return .blobvalue(try reader["blobValue"].read())
            case "timestampValue":
                return .timestampvalue(try reader["timestampValue"].readTimestamp(format: .epochSeconds))
            case "inheritedTimestamp":
                return .inheritedtimestamp(try reader["inheritedTimestamp"].readTimestamp(format: .httpDate))
            case "enumValue":
                return .enumvalue(try reader["enumValue"].read())
            case "listValue":
                return .listvalue(try reader["listValue"].readList(memberReadingClosure: Swift.String.read(from:), memberNodeInfo: "member", isFlattened: false))
            case "mapValue":
                return .mapvalue(try reader["mapValue"].readMap(valueReadingClosure: Swift.String.read(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false))
            case "structureValue":
                return .structurevalue(try reader["structureValue"].read(with: ExampleClientTypes.GreetingWithErrorsOutput.read(from:)))
            default:
                return .sdkUnknown(name ?? "")
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it generates codable conformance for a recursive union`() {
        val contents = getModelFileContents("example", "IndirectEnum+ReadWrite.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension ExampleClientTypes.IndirectEnum {

    static func write(value: ExampleClientTypes.IndirectEnum?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        switch value {
            case let .other(other):
                try writer["other"].write(other)
            case let .some(some):
                try writer["some"].write(some, writingClosure: ExampleClientTypes.IndirectEnum.write(value:to:))
            case let .sdkUnknown(sdkUnknown):
                try writer["sdkUnknown"].write(sdkUnknown)
        }
    }

    static func read(from reader: SmithyJSON.Reader) throws -> ExampleClientTypes.IndirectEnum {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        let name = reader.children.filter { ${'$'}0.hasContent }.first { ${'$'}0.nodeInfo.name != "__type" }?.nodeInfo.name
        switch name {
            case "some":
                return .some(try reader["some"].read(with: ExampleClientTypes.IndirectEnum.read(from:)))
            case "other":
                return .other(try reader["other"].read())
            default:
                return .sdkUnknown(name ?? "")
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
