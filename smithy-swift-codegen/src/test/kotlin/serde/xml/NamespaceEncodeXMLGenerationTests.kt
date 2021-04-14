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
        val contents = getFileContents(context.manifest, "/example/models/XmlNamespacesInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNamespacesInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nested
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://foo.com", forKey: Key("xmlns"))
                    }
                    if let nested = nested {
                        try container.encode(nested, forKey: Key("nested"))
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 xmlnamespace, XmlNamespacesInput, DynamicNodeEncoding`() {
        val context = setupTests("Isolated/Restxml/xml-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNamespacesInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlNamespacesInput: DynamicNodeEncoding {
                public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns"
                    ]
                    if let key = key as? Key {
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
        val contents = getFileContents(context.manifest, "/example/models/XmlNamespaceNested+Codable.swift")
        val expectedContents =
            """
            extension XmlNamespaceNested: Codable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case foo
                    case values
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://boo.com", forKey: Key("xmlns"))
                    }
                    if let foo = foo {
                        var fooContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("foo"))
                        try fooContainer.encode(foo, forKey: Key(""))
                        try fooContainer.encode("http://baz.com", forKey: Key("xmlns:baz"))
                    }
                    if let values = values {
                        var valuesContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("values"))
                        try valuesContainer.encode("http://qux.com", forKey: Key("xmlns"))
                        for string0 in values {
                            var valuesContainer0 = valuesContainer.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                            try valuesContainer0.encode(string0, forKey: Key(""))
                            try valuesContainer0.encode("http://bux.com", forKey: Key("xmlns"))
                        }
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let fooDecoded = try containerValues.decodeIfPresent(String.self, forKey: .foo)
                    foo = fooDecoded
                    if containerValues.contains(.values) {
                        struct KeyVal0{struct member{}}
                        let valuesWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .values)
                        if let valuesWrappedContainer = valuesWrappedContainer {
                            let valuesContainer = try valuesWrappedContainer.decodeIfPresent([String].self, forKey: .member)
                            var valuesBuffer:[String]? = nil
                            if let valuesContainer = valuesContainer {
                                valuesBuffer = [String]()
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
        val contents = getFileContents(context.manifest, "/example/models/XmlNamespaceNested+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlNamespaceNested: DynamicNodeEncoding {
                public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns",
                        "xmlns:baz"
                    ]
                    if let key = key as? Key {
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
        val contents = getFileContents(context.manifest, "/example/models/XmlNamespaceNestedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNamespaceNestedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nested
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://foo.com", forKey: Key("xmlns"))
                    }
                    if let nested = nested {
                        var nestedContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("nested"))
                        try nestedContainer.encode("http://aux.com", forKey: Key("xmlns"))
                        for xmlnestednamespacedlist0 in nested {
                            if let xmlnestednamespacedlist0 = xmlnestednamespacedlist0 {
                                var xmlnestednamespacedlist0Container0 = nestedContainer.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                try xmlnestednamespacedlist0Container0.encode("http://bux.com", forKey: Key("xmlns:baz"))
                                for string1 in xmlnestednamespacedlist0 {
                                    var xmlnestednamespacedlist0Container1 = xmlnestednamespacedlist0Container0.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                    try xmlnestednamespacedlist0Container1.encode(string1, forKey: Key(""))
                                    try xmlnestednamespacedlist0Container1.encode("http://bar.com", forKey: Key("xmlns:bzzzz"))
                                }
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
        val contents = getFileContents(context.manifest, "/example/models/XmlNamespaceNestedListInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlNamespaceNestedListInput: DynamicNodeEncoding {
                public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns",
                        "xmlns:baz",
                        "xmlns:bzzzz"
                    ]
                    if let key = key as? Key {
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
        val contents = getFileContents(context.manifest, "/example/models/XmlNamespaceFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNamespaceFlattenedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nested
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://foo.com", forKey: Key("xmlns"))
                    }
                    if let nested = nested {
                        if nested.isEmpty {
                            var nestedContainer = container.nestedUnkeyedContainer(forKey: Key("nested"))
                            try nestedContainer.encodeNil()
                        } else {
                            for string0 in nested {
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("nested"))
                                try nestedContainer0.encode("http://aux.com", forKey: Key("xmlns:baz"))
                                try nestedContainer0.encode(string0, forKey: Key(""))
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
        val contents = getFileContents(context.manifest, "/example/models/XmlNamespaceFlattenedListInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlNamespaceFlattenedListInput: DynamicNodeEncoding {
                public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns",
                        "xmlns:baz"
                    ]
                    if let key = key as? Key {
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
