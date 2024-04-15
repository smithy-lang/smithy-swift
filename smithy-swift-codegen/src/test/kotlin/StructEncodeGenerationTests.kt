/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer

class StructEncodeGenerationTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        model = RecursiveShapeBoxer.transform(model)
        return model.newTestContext()
    }
    val newTestContext = newTestContext()
    init {
        newTestContext.generator.generateSerializers(newTestContext.generationCtx)
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates encodable conformance in correct file`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/SmokeTestInput+Write.swift"))
    }

    @Test
    fun `it creates encodable conformance for nested structures`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested+ReadWrite.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested2+ReadWrite.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested3+ReadWrite.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested4+ReadWrite.swift"))
    }

    @Test
    fun `it creates smoke test request encodable conformance`() {
        val contents = getModelFileContents("example", "SmokeTestInput+Write.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension SmokeTestInput {

    static func write(value: SmokeTestInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["payload1"].write(value.payload1)
        try writer["payload2"].write(value.payload2)
        try writer["payload3"].write(value.payload3, writingClosure: Nested.write(value:to:))
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes nested documents with aggregate shapes`() {
        val contents = getModelFileContents("example", "Nested4+ReadWrite.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension Nested4 {

    static func write(value: Nested4?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["intList"].writeList(value.intList, memberWritingClosure: Swift.Int.write(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["intMap"].writeMap(value.intMap, valueWritingClosure: Swift.Int.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["member1"].write(value.member1)
        try writer["stringMap"].writeMap(value.stringMap, valueWritingClosure: listWritingClosure(memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "member", isFlattened: false), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }

    static func read(from reader: SmithyJSON.Reader) throws -> Nested4 {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = Nested4()
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
    fun `it provides encodable conformance to operation inputs with timestamps`() {
        val contents = getModelFileContents("example", "TimestampInputInput+Write.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension TimestampInputInput {

    static func write(value: TimestampInputInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["dateTime"].writeTimestamp(value.dateTime, format: .dateTime)
        try writer["epochSeconds"].writeTimestamp(value.epochSeconds, format: .epochSeconds)
        try writer["httpDate"].writeTimestamp(value.httpDate, format: .httpDate)
        try writer["inheritedTimestamp"].writeTimestamp(value.inheritedTimestamp, format: .httpDate)
        try writer["normal"].writeTimestamp(value.normal, format: .epochSeconds)
        try writer["timestampList"].writeList(value.timestampList, memberWritingClosure: timestampWritingClosure(format: .dateTime), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes maps correctly`() {
        val contents = getModelFileContents("example", "MapInputInput+Write.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension MapInputInput {

    static func write(value: MapInputInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["blobMap"].writeMap(value.blobMap, valueWritingClosure: ClientRuntime.Data.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["dateMap"].writeMap(value.dateMap, valueWritingClosure: timestampWritingClosure(format: .httpDate), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["enumMap"].writeMap(value.enumMap, valueWritingClosure: MyEnum.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["intMap"].writeMap(value.intMap, valueWritingClosure: Swift.Int.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["structMap"].writeMap(value.structMap, valueWritingClosure: ReachableOnlyThroughMap.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes nested enums correctly`() {
        val contents = getModelFileContents("example", "EnumInputInput+Write.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension EnumInputInput {

    static func write(value: EnumInputInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["nestedWithEnum"].write(value.nestedWithEnum, writingClosure: NestedEnum.write(value:to:))
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)

        val contents2 = getModelFileContents("example", "NestedEnum+ReadWrite.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents2 = """
extension NestedEnum {

    static func write(value: NestedEnum?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["myEnum"].write(value.myEnum)
    }

    static func read(from reader: SmithyJSON.Reader) throws -> NestedEnum {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = NestedEnum()
        value.myEnum = try reader["myEnum"].readIfPresent()
        return value
    }
}
"""
        contents2.shouldContainOnlyOnce(expectedContents2)
    }

    @Test
    fun `it encodes recursive boxed types correctly`() {
        val contents = getModelFileContents(
            "example",
            "RecursiveShapesInputOutputNested1+ReadWrite.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension RecursiveShapesInputOutputNested1 {

    static func write(value: RecursiveShapesInputOutputNested1?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["foo"].write(value.foo)
        try writer["nested"].write(value.nested, writingClosure: RecursiveShapesInputOutputNested2.write(value:to:))
    }

    static func read(from reader: SmithyJSON.Reader) throws -> RecursiveShapesInputOutputNested1 {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = RecursiveShapesInputOutputNested1()
        value.foo = try reader["foo"].readIfPresent()
        value.nested = try reader["nested"].readIfPresent(with: RecursiveShapesInputOutputNested2.read(from:))
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
extension RecursiveShapesInputOutputNested2 {

    static func write(value: RecursiveShapesInputOutputNested2?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["bar"].write(value.bar)
        try writer["recursiveMember"].write(value.recursiveMember, writingClosure: RecursiveShapesInputOutputNested1.write(value:to:))
    }

    static func read(from reader: SmithyJSON.Reader) throws -> RecursiveShapesInputOutputNested2 {
        guard reader.hasContent else { throw SmithyReadWrite.ReaderError.requiredValueNotPresent }
        var value = RecursiveShapesInputOutputNested2()
        value.bar = try reader["bar"].readIfPresent()
        value.recursiveMember = try reader["recursiveMember"].readIfPresent(with: RecursiveShapesInputOutputNested1.read(from:))
        return value
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes structure with sparse list`() {
        val contents = getModelFileContents("example", "JsonListsInput+Write.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension JsonListsInput {

    static func write(value: JsonListsInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["booleanList"].writeList(value.booleanList, memberWritingClosure: Swift.Bool.write(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["integerList"].writeList(value.integerList, memberWritingClosure: Swift.Int.write(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["nestedStringList"].writeList(value.nestedStringList, memberWritingClosure: listWritingClosure(memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        try writer["sparseStringList"].writeList(value.sparseStringList, memberWritingClosure: sparseFormOf(writingClosure: Swift.String.write(value:to:)), memberNodeInfo: "member", isFlattened: false)
        try writer["stringList"].writeList(value.stringList, memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["stringSet"].writeList(value.stringSet, memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["timestampList"].writeList(value.timestampList, memberWritingClosure: timestampWritingClosure(format: .dateTime), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes structure with sparse map`() {
        val contents = getModelFileContents("example", "JsonMapsInput+Write.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension JsonMapsInput {

    static func write(value: JsonMapsInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["denseBooleanMap"].writeMap(value.denseBooleanMap, valueWritingClosure: Swift.Bool.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["denseNumberMap"].writeMap(value.denseNumberMap, valueWritingClosure: Swift.Int.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["denseStringMap"].writeMap(value.denseStringMap, valueWritingClosure: Swift.String.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["denseStructMap"].writeMap(value.denseStructMap, valueWritingClosure: GreetingStruct.write(value:to:), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["sparseBooleanMap"].writeMap(value.sparseBooleanMap, valueWritingClosure: sparseFormOf(writingClosure: Swift.Bool.write(value:to:)), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["sparseNumberMap"].writeMap(value.sparseNumberMap, valueWritingClosure: sparseFormOf(writingClosure: Swift.Int.write(value:to:)), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["sparseStringMap"].writeMap(value.sparseStringMap, valueWritingClosure: sparseFormOf(writingClosure: Swift.String.write(value:to:)), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
        try writer["sparseStructMap"].writeMap(value.sparseStructMap, valueWritingClosure: sparseFormOf(writingClosure: GreetingStruct.write(value:to:)), keyNodeInfo: "key", valueNodeInfo: "value", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode checks for 0 or false for primitive types`() {
        val contents = getModelFileContents("example", "PrimitiveTypesInput+Write.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension PrimitiveTypesInput {

    static func write(value: PrimitiveTypesInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["booleanVal"].write(value.booleanVal)
        try writer["byteVal"].write(value.byteVal)
        try writer["doubleVal"].write(value.doubleVal)
        try writer["floatVal"].write(value.floatVal)
        try writer["intVal"].write(value.intVal)
        try writer["longVal"].write(value.longVal)
        try writer["primitiveBooleanVal"].write(value.primitiveBooleanVal)
        try writer["primitiveByteVal"].write(value.primitiveByteVal)
        try writer["primitiveDoubleVal"].write(value.primitiveDoubleVal)
        try writer["primitiveFloatVal"].write(value.primitiveFloatVal)
        try writer["primitiveIntVal"].write(value.primitiveIntVal)
        try writer["primitiveLongVal"].write(value.primitiveLongVal)
        try writer["primitiveShortVal"].write(value.primitiveShortVal)
        try writer["shortVal"].write(value.shortVal)
        try writer["str"].write(value.str)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
