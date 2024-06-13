/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class StructEncodeGenerationIsolatedTests {
    @Test
    fun `BlobInput`() {
        val context = setupTests("Isolated/BlobInput.smithy", "com.test#Example")
        Assertions.assertTrue(context.manifest.hasFile("Sources/example/models/BlobInputInput+Write.swift"))
    }

    @Test
    fun `BlobInput Contents`() {
        val context = setupTests("Isolated/BlobInput.smithy", "com.test#Example")
        val contents = getModelFileContents("Sources/example", "BlobInputInput+Write.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
    }

    @Test
    fun `EnumInput`() {
        val testContext = setupTests("Isolated/EnumInput.smithy", "com.test#Example")
        Assertions.assertTrue(testContext.manifest.hasFile("Sources/example/models/EnumInputInput+Write.swift"))
    }

    @Test
    fun `EnumInput Contents`() {
        val context = setupTests("Isolated/EnumInput.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/example/models/EnumInputInput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct EnumInputInput {
                public var enumHeader: ExampleClientTypes.MyEnum?
                public var nestedWithEnum: ExampleClientTypes.NestedEnum?
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `it can handle nested string lists`() {
        val context = setupTests("Isolated/NestedStringList.smithy", "com.test#Example")
        print(context.manifest.files)
        val contents = getFileContents(context.manifest, "Sources/example/models/JsonListsInput+Write.swift")
        contents.shouldSyntacticSanityCheck()

        val expectedContents = """
extension JsonListsInput {

    static func write(value: JsonListsInput?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["nestedStringList"].writeList(value.nestedStringList, memberWritingClosure: SmithyReadWrite.listWritingClosure(memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false), memberNodeInfo: "member", isFlattened: false)
        try writer["stringList"].writeList(value.stringList, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false)
        try writer["stringSet"].writeList(value.stringSet, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "member", isFlattened: false)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
