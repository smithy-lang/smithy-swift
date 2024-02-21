/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class MemberShapeDecodeXMLGeneratorTests {

    @Test
    fun `001 set default value for a missing value of a scalar member`() {
        val context = setupTests("Isolated/Restxml/xml-scalarmember-default-value.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/SimpleScalarPropertiesOutputBody+Decodable.swift")
        val expectedContents = """
extension SimpleScalarPropertiesOutputBody {

    static var readingClosure: SmithyReadWrite.ReadingClosure<SimpleScalarPropertiesOutput, SmithyXML.Reader> {
        return { reader in
            guard reader.content != nil else { return nil }
            var value = SimpleScalarPropertiesOutput()
            value.stringValue = try reader["stringValue"].readIfPresent() ?? test
            value.trueBooleanValue = try reader["trueBooleanValue"].readIfPresent() ?? false
            value.falseBooleanValue = try reader["falseBooleanValue"].readIfPresent()
            value.byteValue = try reader["byteValue"].readIfPresent()
            value.shortValue = try reader["shortValue"].readIfPresent()
            value.integerValue = try reader["integerValue"].readIfPresent() ?? 5
            value.longValue = try reader["longValue"].readIfPresent()
            value.floatValue = try reader["floatValue"].readIfPresent() ?? 2.4
            value.`protocol` = try reader["protocol"].readIfPresent()
            value.doubleValue = try reader["DoubleDribble"].readIfPresent()
            return value
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2023-08-08", "Rest Xml Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
