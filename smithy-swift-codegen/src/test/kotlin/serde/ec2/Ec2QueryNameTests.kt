/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package serde.ec2

import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import mocks.MockHttpEC2QueryProtocolGenerator
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class Ec2QueryNameTests {
    @Test
    fun `001 encode simple types`() {
        val context = setupTests("Isolated/ec2/query-simple.smithy", "aws.protocoltests.ec2#AwsEc2")
        val contents = getFileContents(context.manifest, "/Example/models/Ec2SimpleInputParamsInput+Write.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension Ec2SimpleInputParamsInput {

    static func write(value: Ec2SimpleInputParamsInput?, to writer: SmithyFormURL.Writer) throws {
        guard let value else { return }
        try writer["BamInt"].write(value.bamInt)
        try writer["BarString"].write(value.barString)
        try writer["BazBoolean"].write(value.bazBoolean)
        try writer["BooDouble"].write(value.booDouble)
        try writer["FzzEnum"].write(value.fzzEnum)
        try writer["B"].write(value.hasQueryAndXmlNameString)
        try writer["A"].write(value.hasQueryNameString)
        try writer["QuxBlob"].write(value.quxBlob)
        try writer["C"].write(value.usesXmlNameString)
        try writer["Action"].write("Ec2SimpleInputParams")
        try writer["Version"].write("2020-01-08")
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpEC2QueryProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2020-01-08", "Ec2 query protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
