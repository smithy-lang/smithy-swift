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

class AttributeDecodeXMLGenerationTests {
    @Test
    fun `001 xml attributes decode for input type`() {
        val context = setupTests("Isolated/Restxml/xml-attr.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlAttributesOutputResponseBody+DynamicNodeDecoding.swift")
        val expectedContents = """
        extension XmlAttributesOutputResponseBody: ClientRuntime.DynamicNodeDecoding {
            public static func nodeDecoding(for key: Swift.CodingKey) -> ClientRuntime.NodeDecoding {
                switch(key) {
                    case XmlAttributesOutputResponseBody.CodingKeys.foo: return .element
                    case XmlAttributesOutputResponseBody.CodingKeys.attr: return .attribute
                    default:
                        return .element
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
