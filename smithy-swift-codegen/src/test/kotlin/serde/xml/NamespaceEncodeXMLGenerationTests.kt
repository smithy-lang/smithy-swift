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

class NamespaceEncodeXMLGenerationTests {
    @Test
    fun `001 xmlnamespace, XmlNamespacesInput, Encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespacesInput+Encodable.swift")
        val expectedContents = """
extension XmlNamespacesInput: Swift.Encodable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case nested
    }

    static func writingClosure(_ value: XmlNamespacesInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer[.init("nested", namespace: .init(prefix: "", uri: "http://boo.com"))].write(value.nested, writingClosure: RestXmlProtocolClientTypes.XmlNamespaceNested.writingClosure(_:to:))
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 xmlnamespace, XmlNamespaceNested`() {
        val context = setupTests("Isolated/Restxml/xml-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespaceNested+Codable.swift")
        val expectedContents =
            """
            extension RestXmlProtocolClientTypes.XmlNamespaceNested: Swift.Codable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case foo
                    case values
                }
            
                static func writingClosure(_ value: RestXmlProtocolClientTypes.XmlNamespaceNested?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("foo", namespace: .init(prefix: "baz", uri: "http://baz.com"))].write(value.foo)
                    try writer[.init("values", namespace: .init(prefix: "", uri: "http://qux.com"))].writeList(value.values, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member", namespace: .init(prefix: "", uri: "http://bux.com")), isFlattened: false)
                }
            
                public init(from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let fooDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .foo)
                    foo = fooDecoded
                    if containerValues.contains(.values) {
                        struct KeyVal0{struct member{}}
                        let valuesWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .values)
                        if let valuesWrappedContainer = valuesWrappedContainer {
                            let valuesContainer = try valuesWrappedContainer.decodeIfPresent([Swift.String].self, forKey: .member)
                            var valuesBuffer:[Swift.String]? = nil
                            if let valuesContainer = valuesContainer {
                                valuesBuffer = [Swift.String]()
                                for stringContainer0 in valuesContainer {
                                    valuesBuffer?.append(stringContainer0)
                                }
                            }
                            values = valuesBuffer
                        } else {
                            values = []
                        }
                    } else {
                        values = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 xmlnamespace nested list, Encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-nestedlist.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespaceNestedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNamespaceNestedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nested
                }
            
                static func writingClosure(_ value: XmlNamespaceNestedListInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nested", namespace: .init(prefix: "", uri: "http://aux.com"))].writeList(value.nested, memberWritingClosure: SmithyXML.listWritingClosure(memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member", namespace: .init(prefix: "bzzzz", uri: "http://bar.com")), isFlattened: false), memberNodeInfo: .init("member", namespace: .init(prefix: "baz", uri: "http://bux.com")), isFlattened: false)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 xmlnamespace nested flattened list, encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-flattenedlist.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespaceFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNamespaceFlattenedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nested
                }
            
                static func writingClosure(_ value: XmlNamespaceFlattenedListInput?, to writer: SmithyXML.Writer) throws {
                    guard let value else { writer.detach(); return }
                    try writer[.init("nested", namespace: .init(prefix: "baz", uri: "http://aux.com"))].writeList(value.nested, memberWritingClosure: Swift.String.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: true)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `010 xmlnamespace on service, encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-onservice.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespacesOnServiceInput+Encodable.swift")
        val expectedContents = """
extension XmlNamespacesOnServiceInput: Swift.Encodable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case foo
        case nested
    }

    static func writingClosure(_ value: XmlNamespacesOnServiceInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer[.init("foo")].write(value.foo)
        try writer[.init("nested", namespace: .init(prefix: "xsi", uri: "https://example.com"))].write(value.nested, writingClosure: RestXmlProtocolClientTypes.NestedWithNamespace.writingClosure(_:to:))
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 xmlnamespace on service, encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-onservice-overridable.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespacesOnServiceOverridableInput+Encodable.swift")
        val expectedContents = """
extension XmlNamespacesOnServiceOverridableInput: Swift.Encodable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case foo
        case nested
    }

    static func writingClosure(_ value: XmlNamespacesOnServiceOverridableInput?, to writer: SmithyXML.Writer) throws {
        guard let value else { writer.detach(); return }
        try writer[.init("foo")].write(value.foo)
        try writer[.init("nested", namespace: .init(prefix: "xsi", uri: "https://example.com"))].write(value.nested, writingClosure: RestXmlProtocolClientTypes.NestedWithNamespace.writingClosure(_:to:))
    }
}
"""
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
