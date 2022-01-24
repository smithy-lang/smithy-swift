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
        val contents = getFileContents(context.manifest, "/Example/models/Ec2SimpleInputParamsInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension Ec2SimpleInputParamsInput: Swift.Encodable, Runtime.Reflection {
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: Runtime.Key.self)
                    if let bamInt = bamInt {
                        try container.encode(bamInt, forKey: Runtime.Key("BamInt"))
                    }
                    if let barString = barString {
                        try container.encode(barString, forKey: Runtime.Key("BarString"))
                    }
                    if let bazBoolean = bazBoolean {
                        try container.encode(bazBoolean, forKey: Runtime.Key("BazBoolean"))
                    }
                    if let booDouble = booDouble {
                        try container.encode(booDouble, forKey: Runtime.Key("BooDouble"))
                    }
                    if let fzzEnum = fzzEnum {
                        try container.encode(fzzEnum, forKey: Runtime.Key("FzzEnum"))
                    }
                    if let hasQueryAndXmlNameString = hasQueryAndXmlNameString {
                        try container.encode(hasQueryAndXmlNameString, forKey: Runtime.Key("B"))
                    }
                    if let hasQueryNameString = hasQueryNameString {
                        try container.encode(hasQueryNameString, forKey: Runtime.Key("A"))
                    }
                    if let quxBlob = quxBlob {
                        try container.encode(quxBlob.base64EncodedString(), forKey: Runtime.Key("QuxBlob"))
                    }
                    if let usesXmlNameString = usesXmlNameString {
                        try container.encode(usesXmlNameString, forKey: Runtime.Key("C"))
                    }
                    try container.encode("Ec2SimpleInputParams", forKey:Runtime.Key("Action"))
                    try container.encode("2020-01-08", forKey:Runtime.Key("Version"))
                }
            }
            """.trimIndent()
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
