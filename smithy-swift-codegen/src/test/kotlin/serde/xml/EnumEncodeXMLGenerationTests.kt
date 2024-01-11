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

class EnumEncodeXMLGenerationTests {
    @Test
    fun `001 encode enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case fooEnum1
                    case fooEnum2
                    case fooEnum3
                    case fooEnumList
                }
            
                static func writingClosure(_ value: XmlEnumsInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("fooEnum1")].write(value.fooEnum1)
                    try writer[.init("fooEnum2")].write(value.fooEnum2)
                    try writer[.init("fooEnum3")].write(value.fooEnum3)
                    try writer[.init("fooEnumList")].writeList(value.fooEnumList, memberWritingClosure: RestXmlProtocolClientTypes.FooEnum.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode nested enum`() {
        val context = setupTests("Isolated/Restxml/xml-enums.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEnumsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEnumsNestedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedEnumsList
                }
            
                static func writingClosure(_ value: XmlEnumsNestedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedEnumsList")].writeList(value.nestedEnumsList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: RestXmlProtocolClientTypes.FooEnum.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
