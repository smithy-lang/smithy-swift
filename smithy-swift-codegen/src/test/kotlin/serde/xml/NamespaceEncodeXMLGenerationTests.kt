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
        val expectedContents =
            """
            extension XmlNamespacesInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nested
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://foo.com", forKey: ClientRuntime.Key("xmlns"))
                    }
                    if let nested = nested {
                        try container.encode(nested, forKey: ClientRuntime.Key("nested"))
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 xmlnamespace, XmlNamespacesInput, DynamicNodeEncoding`() {
        val context = setupTests("Isolated/Restxml/xml-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespacesInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlNamespacesInput: XMLRuntime.DynamicNodeEncoding {
                public static func nodeEncoding(for key: Swift.CodingKey) -> XMLRuntime.NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns"
                    ]
                    if let key = key as? ClientRuntime.Key {
                        if xmlNamespaceValues.contains(key.stringValue) {
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
    fun `003 xmlnamespace, XmlNamespaceNested`() {
        val context = setupTests("Isolated/Restxml/xml-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespaceNested+Codable.swift")
        val expectedContents =
            """
            extension RestXmlProtocolClientTypes.XmlNamespaceNested: Swift.Codable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case foo
                    case values
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://boo.com", forKey: ClientRuntime.Key("xmlns"))
                    }
                    if let foo = foo {
                        var fooContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("foo"))
                        try fooContainer.encode(foo, forKey: ClientRuntime.Key(""))
                        try fooContainer.encode("http://baz.com", forKey: ClientRuntime.Key("xmlns:baz"))
                    }
                    if let values = values {
                        var valuesContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("values"))
                        try valuesContainer.encode("http://qux.com", forKey: ClientRuntime.Key("xmlns"))
                        for string0 in values {
                            var valuesContainer0 = valuesContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                            try valuesContainer0.encode(string0, forKey: ClientRuntime.Key(""))
                            try valuesContainer0.encode("http://bux.com", forKey: ClientRuntime.Key("xmlns"))
                        }
                    }
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let fooDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .foo)
                    foo = fooDecoded
                    if containerValues.contains(.values) {
                        struct KeyVal0{struct member{}}
                        let valuesWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: XMLRuntime.CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .values)
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
    fun `004 xmlnamespace, XmlNamespaceNested, nested structure needs dynamic node encoding`() {
        val context = setupTests("Isolated/Restxml/xml-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespaceNested+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension RestXmlProtocolClientTypes.XmlNamespaceNested: XMLRuntime.DynamicNodeEncoding {
                public static func nodeEncoding(for key: Swift.CodingKey) -> XMLRuntime.NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns",
                        "xmlns:baz"
                    ]
                    if let key = key as? ClientRuntime.Key {
                        if xmlNamespaceValues.contains(key.stringValue) {
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
    fun `005 xmlnamespace nested list, Encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-nestedlist.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespaceNestedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNamespaceNestedListInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nested
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://foo.com", forKey: ClientRuntime.Key("xmlns"))
                    }
                    if let nested = nested {
                        var nestedContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nested"))
                        try nestedContainer.encode("http://aux.com", forKey: ClientRuntime.Key("xmlns"))
                        for xmlnestednamespacedlist0 in nested {
                            var xmlnestednamespacedlist0Container0 = nestedContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                            try xmlnestednamespacedlist0Container0.encode("http://bux.com", forKey: ClientRuntime.Key("xmlns:baz"))
                            for string1 in xmlnestednamespacedlist0 {
                                var xmlnestednamespacedlist0Container1 = xmlnestednamespacedlist0Container0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                                try xmlnestednamespacedlist0Container1.encode(string1, forKey: ClientRuntime.Key(""))
                                try xmlnestednamespacedlist0Container1.encode("http://bar.com", forKey: ClientRuntime.Key("xmlns:bzzzz"))
                            }
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 xmlnamespace nested list, dynamic node encoding`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-nestedlist.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespaceNestedListInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlNamespaceNestedListInput: XMLRuntime.DynamicNodeEncoding {
                public static func nodeEncoding(for key: Swift.CodingKey) -> XMLRuntime.NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns",
                        "xmlns:baz",
                        "xmlns:bzzzz"
                    ]
                    if let key = key as? ClientRuntime.Key {
                        if xmlNamespaceValues.contains(key.stringValue) {
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
    fun `007 xmlnamespace nested flattened list, encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-flattenedlist.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespaceFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNamespaceFlattenedListInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nested
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://foo.com", forKey: ClientRuntime.Key("xmlns"))
                    }
                    if let nested = nested {
                        if nested.isEmpty {
                            var nestedContainer = container.nestedUnkeyedContainer(forKey: ClientRuntime.Key("nested"))
                            try nestedContainer.encodeNil()
                        } else {
                            for string0 in nested {
                                var nestedContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nested"))
                                try nestedContainer0.encode("http://aux.com", forKey: ClientRuntime.Key("xmlns:baz"))
                                try nestedContainer0.encode(string0, forKey: ClientRuntime.Key(""))
                            }
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 xmlnamespace nested flattened list, dynamic node encoding`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-flattenedlist.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespaceFlattenedListInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlNamespaceFlattenedListInput: XMLRuntime.DynamicNodeEncoding {
                public static func nodeEncoding(for key: Swift.CodingKey) -> XMLRuntime.NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns",
                        "xmlns:baz"
                    ]
                    if let key = key as? ClientRuntime.Key {
                        if xmlNamespaceValues.contains(key.stringValue) {
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
    fun `009 xmlnamespace on service, dynamic node encoding`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-onservice.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespacesOnServiceInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlNamespacesOnServiceInput: XMLRuntime.DynamicNodeEncoding {
                public static func nodeEncoding(for key: Swift.CodingKey) -> XMLRuntime.NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns",
                        "xmlns:xsi"
                    ]
                    if let key = key as? ClientRuntime.Key {
                        if xmlNamespaceValues.contains(key.stringValue) {
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
    fun `010 xmlnamespace on service, encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-onservice.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespacesOnServiceInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNamespacesOnServiceInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case foo
                    case nested
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("https://example.com", forKey: ClientRuntime.Key("xmlns"))
                    }
                    if let foo = foo {
                        try container.encode(foo, forKey: ClientRuntime.Key("foo"))
                    }
                    if let nested = nested {
                        var nestedContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nested"))
                        try nestedContainer.encode(nested, forKey: ClientRuntime.Key(""))
                        try nestedContainer.encode("https://example.com", forKey: ClientRuntime.Key("xmlns:xsi"))
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 xmlnamespace on service, encodable`() {
        val context = setupTests("Isolated/Restxml/xml-namespace-onservice-overridable.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNamespacesOnServiceOverridableInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNamespacesOnServiceOverridableInput: Swift.Encodable, ClientRuntime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case foo
                    case nested
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("https://overridable.com", forKey: ClientRuntime.Key("xmlns"))
                    }
                    if let foo = foo {
                        try container.encode(foo, forKey: ClientRuntime.Key("foo"))
                    }
                    if let nested = nested {
                        var nestedContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nested"))
                        try nestedContainer.encode(nested, forKey: ClientRuntime.Key(""))
                        try nestedContainer.encode("https://example.com", forKey: ClientRuntime.Key("xmlns:xsi"))
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
