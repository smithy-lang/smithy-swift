package software.amazon.smithy.swift.codegen.basicshapes

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.asSmithy
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.getModelFileContents
import software.amazon.smithy.swift.codegen.model.AddOperationShapes
import software.amazon.smithy.swift.codegen.model.NeedsReaderWriterTransformer
import software.amazon.smithy.swift.codegen.model.NestedShapeTransformer
import software.amazon.smithy.swift.codegen.newTestContext
import software.amazon.smithy.swift.codegen.shouldSyntacticSanityCheck

class UnionDecodeGeneratorTests {
    var model = javaClass.classLoader.getResource("http-binding-protocol-generator-test.smithy").asSmithy()

    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
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
        Assertions.assertTrue(newTestContext.manifest.hasFile("Sources/example/models/MyUnion+ReadWrite.swift"))
    }

    @Test
    fun `it decodes a union with various member shape types`() {
        val contents = getModelFileContents("Sources/example", "MyUnion+ReadWrite.swift", newTestContext.manifest)
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
                try writer["inheritedTimestamp"].writeTimestamp(inheritedtimestamp, format: SmithyTimestamps.TimestampFormat.httpDate)
            case let .listvalue(listvalue):
                try writer["listValue"].writeList(listvalue, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false)
            case let .mapvalue(mapvalue):
                try writer["mapValue"].writeMap(mapvalue, valueWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
            case let .numbervalue(numbervalue):
                try writer["numberValue"].write(numbervalue)
            case let .stringvalue(stringvalue):
                try writer["stringValue"].write(stringvalue)
            case let .structurevalue(structurevalue):
                try writer["structureValue"].write(structurevalue, with: ExampleClientTypes.GreetingWithErrorsOutput.write(value:to:))
            case let .timestampvalue(timestampvalue):
                try writer["timestampValue"].writeTimestamp(timestampvalue, format: SmithyTimestamps.TimestampFormat.epochSeconds)
            case let .sdkUnknown(sdkUnknown):
                try writer["sdkUnknown"].write(sdkUnknown)
        }
    }

    static func read(from reader: SmithyJSON.Reader) throws -> ExampleClientTypes.MyUnion {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        let name = reader.children.filter { ${'$'}0.hasContent && ${'$'}0.nodeInfo.name != "__type" }.first?.nodeInfo.name
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
                return .timestampvalue(try reader["timestampValue"].readTimestamp(format: SmithyTimestamps.TimestampFormat.epochSeconds))
            case "inheritedTimestamp":
                return .inheritedtimestamp(try reader["inheritedTimestamp"].readTimestamp(format: SmithyTimestamps.TimestampFormat.httpDate))
            case "enumValue":
                return .enumvalue(try reader["enumValue"].read())
            case "listValue":
                return .listvalue(try reader["listValue"].readList(memberReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), memberNodeInfo: "member", isFlattened: false))
            case "mapValue":
                return .mapvalue(try reader["mapValue"].readMap(valueReadingClosure: SmithyReadWrite.ReadingClosures.readString(from:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false))
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
}
