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

class TimeStampEncodeGenerationTests {
    @Test
    fun `001 encode all timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case dateTime
                    case epochSeconds
                    case httpDate
                    case normal
                }
            
                static func writingClosure(_ value: XmlTimestampsInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("dateTime")].writeTimestamp(value.dateTime, format: .dateTime)
                    try writer[.init("epochSeconds")].writeTimestamp(value.epochSeconds, format: .epochSeconds)
                    try writer[.init("httpDate")].writeTimestamp(value.httpDate, format: .httpDate)
                    try writer[.init("normal")].writeTimestamp(value.normal, format: .dateTime)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode nested list with timestamps`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedTimestampList
                }
            
                static func writingClosure(_ value: XmlTimestampsNestedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedTimestampList")].writeList(value.nestedTimestampList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: SmithyXML.timestampWritingClosure(format: .epochSeconds), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 encode nested list with timestamps httpDate`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedHTTPDateInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedHTTPDateInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedTimestampList
                }
            
                static func writingClosure(_ value: XmlTimestampsNestedHTTPDateInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedTimestampList")].writeList(value.nestedTimestampList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: SmithyXML.timestampWritingClosure(format: .httpDate), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 encode nested list with timestamps with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedXmlNameInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedTimestampList
                }
            
                static func writingClosure(_ value: XmlTimestampsNestedXmlNameInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedTimestampList")].writeList(value.nestedTimestampList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: SmithyXML.timestampWritingClosure(format: .epochSeconds), memberNodeInfo: .init("nestedTag2"), isFlattened: false), memberNodeInfo: .init("nestedTag1"), isFlattened: false)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 encode all timestamps, withxmlName`() {
        val context = setupTests("Isolated/Restxml/xml-timestamp-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsXmlNameInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case dateTime
                    case normal = "notNormalName"
                }
            
                static func writingClosure(_ value: XmlTimestampsXmlNameInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("dateTime")].writeTimestamp(value.dateTime, format: .dateTime)
                    try writer[.init("notNormalName")].writeTimestamp(value.normal, format: .dateTime)
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
