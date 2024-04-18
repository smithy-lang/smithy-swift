/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package serde.ec2

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHTTPEC2QueryProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class OnlyFlattenedListEncodeFormURLGeneratorTests {

    @Test
    fun `001 encode different types of lists`() {
        val context = setupTests("Isolated/ec2/query-lists.smithy", "aws.protocoltests.ec2#AwsEc2")
        val contents = getFileContents(context.manifest, "/Example/models/Ec2QueryListsInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension Ec2QueryListsInput {

    static func write(value: Ec2QueryListsInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        try writer["ComplexListArg"].writeList(value.complexListArg, memberWritingClosure: Ec2queryprotocolClientTypes.GreetingStruct.write(value:to:), memberNodeInfo: "Member", isFlattened: true)
        try writer["ListArg"].writeList(value.listArg, memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "Member", isFlattened: true)
        try writer["Hi"].writeList(value.listArgWithXmlName, memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "Item", isFlattened: true)
        try writer["ListArgWithXmlNameMember"].writeList(value.listArgWithXmlNameMember, memberWritingClosure: Swift.String.write(value:to:), memberNodeInfo: "Item", isFlattened: true)
        try writer["Action"].write("Ec2QueryLists")
        try writer["Version"].write("2020-01-08")
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPEC2QueryProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2020-01-08", "Ec2 query protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
