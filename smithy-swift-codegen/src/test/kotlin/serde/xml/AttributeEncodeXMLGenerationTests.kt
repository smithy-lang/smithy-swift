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

class AttributeEncodeXMLGenerationTests {
    @Test
    fun `001 xml attributes encoding for input type`() {
        val context = setupTests("Isolated/Restxml/xml-attr.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlAttributesInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlAttributesInput: XMLRuntime.DynamicNodeEncoding {
                public static func nodeEncoding(for key: Swift.CodingKey) -> XMLRuntime.NodeEncoding {
                    let codingKeys = [
                        "test"
                    ]
                    if let key = key as? Runtime.Key {
                        if codingKeys.contains(key.stringValue) {
                            return .attribute
                        }
                    }
                    return .element
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 creates encodable`() {
        val context = setupTests("Isolated/Restxml/xml-attr.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlAttributesInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlAttributesInput: Swift.Encodable, Runtime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case attr = "test"
                    case foo
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: Runtime.Key.self)
                    if let attr = attr {
                        try container.encode(attr, forKey: Runtime.Key("test"))
                    }
                    if let foo = foo {
                        try container.encode(foo, forKey: Runtime.Key("foo"))
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
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
