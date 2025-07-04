package software.amazon.smithy.swift.codegen.protocolspecificserde.ec2query

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.getFileContents
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPEC2QueryProtocolGenerator
import software.amazon.smithy.swift.codegen.shouldSyntacticSanityCheck

class OnlyFlattenedListEncodeGeneratorTests {
    @Test
    fun `001 encode different types of lists`() {
        val context = setupTests("Isolated/ec2/query-lists.smithy", "aws.protocoltests.ec2#AwsEc2")
        val contents = getFileContents(context.manifest, "Sources/Example/models/Ec2QueryListsInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension Ec2QueryListsInput {

    static func write(value: Ec2QueryListsInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        if !(value.complexListArg?.isEmpty ?? true) {
            try writer["ComplexListArg"].writeList(value.complexListArg, memberWritingClosure: Ec2queryprotocolClientTypes.GreetingStruct.write(value:to:), memberNodeInfo: "Member", isFlattened: true)
        }
        if !(value.listArg?.isEmpty ?? true) {
            try writer["ListArg"].writeList(value.listArg, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "Member", isFlattened: true)
        }
        if !(value.listArgWithXmlName?.isEmpty ?? true) {
            try writer["Hi"].writeList(value.listArgWithXmlName, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "Item", isFlattened: true)
        }
        if !(value.listArgWithXmlNameMember?.isEmpty ?? true) {
            try writer["ListArgWithXmlNameMember"].writeList(value.listArgWithXmlNameMember, memberWritingClosure: SmithyReadWrite.WritingClosures.writeString(value:to:), memberNodeInfo: "Item", isFlattened: true)
        }
        try writer["Action"].write("Ec2QueryLists")
        try writer["Version"].write("2020-01-08")
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(
        smithyFile: String,
        serviceShapeId: String,
    ): TestContext {
        val context =
            TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPEC2QueryProtocolGenerator()) { model ->
                model.defaultSettings(serviceShapeId, "Example", "2020-01-08", "Ec2 query protocol")
            }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
