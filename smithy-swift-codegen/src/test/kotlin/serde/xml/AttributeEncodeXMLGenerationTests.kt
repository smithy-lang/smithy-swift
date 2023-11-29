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
    fun `002 creates encodable`() {
        val context = setupTests("Isolated/Restxml/xml-attr.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlAttributesInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlAttributesInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case attr = "test"
                    case foo
                }
            
                static func writingClosure(_ value: XmlAttributesInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("test", location: .attribute)].write(value.attr)
                    try writer[.init("foo")].write(value.foo)
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
