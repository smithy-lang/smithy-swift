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

class ListEncodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                static func writingClosure(_ value: XmlListXmlNameInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("renamed")].writeList(value.renamedListMembers, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("item"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 nested wrapped list with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameNestedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                static func writingClosure(_ value: XmlListXmlNameNestedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("renamed")].writeList(value.renamedListMembers, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("subItem"), isFlattened: false), memberNodeInfo: .init("item"), isFlattened: false)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 nested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedWrappedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedStringList
                }
            
                static func writingClosure(_ value: XmlNestedWrappedListInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedStringList")].writeList(value.nestedStringList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 nestednested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedWrappedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedNestedStringList
                }
            
                static func writingClosure(_ value: XmlNestedNestedWrappedListInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedNestedStringList")].writeList(value.nestedNestedStringList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 nestednested flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedFlattenedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedNestedStringList
                }
            
                static func writingClosure(_ value: XmlNestedNestedFlattenedListInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedNestedStringList")].writeList(value.nestedNestedStringList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 empty lists`() {
        val context = setupTests("Isolated/Restxml/xml-lists-empty.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyListsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEmptyListsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case booleanList
                    case integerList
                    case stringList
                    case stringSet
                }
            
                static func writingClosure(_ value: XmlEmptyListsInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("booleanList")].writeList(value.booleanList, memberWritingClosure: Swift.Bool.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
                    try writer[.init("integerList")].writeList(value.integerList, memberWritingClosure: Swift.Int.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
                    try writer[.init("stringList")].writeList(value.stringList, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
                    try writer[.init("stringSet")].writeList(value.stringSet, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlWrappedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myGroceryList
                }
            
                static func writingClosure(_ value: XmlWrappedListInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myGroceryList")].writeList(value.myGroceryList, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myGroceryList
                }
            
                static func writingClosure(_ value: XmlFlattenedListInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myGroceryList")].writeList(value.myGroceryList, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: true)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `010 encode nested flattened datetime encodable`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-nested-datetime.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedFlattenedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedFlattenedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedTimestampList
                }
            
                static func writingClosure(_ value: XmlTimestampsNestedFlattenedInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nestedTimestampList")].writeList(value.nestedTimestampList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: SmithyXML.timestampWritingClosure(format: .epochSeconds), memberNodeInfo: .init("member"), isFlattened: false), memberNodeInfo: .init("nestedMember", namespace: .init(prefix: "baz", uri: "http://baz.com")), isFlattened: true)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `011 encode flattened empty list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-emptyFlattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyFlattenedListsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEmptyFlattenedListsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case booleanList
                    case integerList
                    case stringList
                    case stringSet
                }
            
                static func writingClosure(_ value: XmlEmptyFlattenedListsInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("booleanList")].writeList(value.booleanList, memberWritingClosure: Swift.Bool.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
                    try writer[.init("integerList")].writeList(value.integerList, memberWritingClosure: Swift.Int.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
                    try writer[.init("stringList")].writeList(value.stringList, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: true)
                    try writer[.init("stringSet")].writeList(value.stringSet, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: true)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 encode list flattened nested with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListNestedFlattenedXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListNestedFlattenedXmlNameInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedList = "listOfNestedStrings"
                }
            
                static func writingClosure(_ value: XmlListNestedFlattenedXmlNameInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("listOfNestedStrings")].writeList(value.nestedList, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("nestedNestedMember"), isFlattened: false), memberNodeInfo: .init("nestedMember"), isFlattened: true)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `012 encode list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListContainMapInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListContainMapInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myList
                }
            
                static func writingClosure(_ value: XmlListContainMapInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myList")].writeList(value.myList, memberWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: false)
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `013 encode flattened list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListFlattenedContainMapInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListFlattenedContainMapInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myList
                }
            
                static func writingClosure(_ value: XmlListFlattenedContainMapInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("myList")].writeList(value.myList, memberWritingClosure: SmithyXML.mapWritingClosure(valueWritingClosure: Swift.String.writingClosure(_:to:), keyNodeInfo: .init("key"), valueNodeInfo: .init("value"), isFlattened: false), memberNodeInfo: .init("member"), isFlattened: true)
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
