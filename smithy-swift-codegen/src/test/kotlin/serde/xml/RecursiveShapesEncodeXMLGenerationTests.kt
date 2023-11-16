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

class RecursiveShapesEncodeXMLGenerationTests {
    @Test
    fun `001 encode recursive shape Nested1`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/RecursiveShapesInputOutputNested1+Codable.swift")
        val expectedContents =
            """
            extension RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1: Swift.Codable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case foo
                    case nested
                }
            
                static func writingClosure(_ value: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("foo")].write(value.foo)
                    try RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2.writingClosure(value.nested, to: writer[.init("nested")])
                }
            
                public init(from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let fooDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .foo)
                    foo = fooDecoded
                    let nestedDecoded = try containerValues.decodeIfPresent(RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2.self, forKey: .nested)
                    nested = nestedDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode recursive shape Nested2`() {
        val context = setupTests("Isolated/Restxml/xml-recursive.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/RecursiveShapesInputOutputNested2+Codable.swift")
        val expectedContents =
            """
            extension RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2: Swift.Codable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case bar
                    case recursiveMember
                }
            
                static func writingClosure(_ value: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested2?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("bar")].write(value.bar)
                    try RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.writingClosure(value.recursiveMember, to: writer[.init("recursiveMember")])
                }
            
                public init(from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let barDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .bar)
                    bar = barDecoded
                    let recursiveMemberDecoded = try containerValues.decodeIfPresent(RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.self, forKey: .recursiveMember)
                    recursiveMember = recursiveMemberDecoded
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `encode recursive nested shape`() {
        val context = setupTests("Isolated/Restxml/xml-recursive-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedRecursiveShapesInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedRecursiveShapesInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedRecursiveList
                }
            
                static func writingClosure(_ value: XmlNestedRecursiveShapesInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedRecursiveList")].writeList(value.nestedRecursiveList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: RestXmlProtocolClientTypes.RecursiveShapesInputOutputNested1.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false)
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
