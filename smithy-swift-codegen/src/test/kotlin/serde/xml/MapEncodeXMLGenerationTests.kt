package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class MapEncodeXMLGenerationTests {
    @Test
    fun `encode map`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: MapEntry<String, GreetingStruct>.CodingKeys.self, forKey: .myMap)
                        for (string0, greetingstruct0) in myMap {
                            var entry = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct>.CodingKeys.self, forKey: .entry)
                            try entry.encode(string0, forKey: .key)
                            try entry.encode(greetingstruct0, forKey: .value)
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode map with name protocol`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsWithNameProtocolInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsWithNameProtocolInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case `protocol` = "protocol"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let `protocol` = `protocol` {
                        var protocolContainer = container.nestedContainer(keyedBy: MapEntry<String, GreetingStruct>.CodingKeys.self, forKey: .protocol)
                        for (string0, greetingstruct0) in `protocol` {
                            var entry = protocolContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct>.CodingKeys.self, forKey: .entry)
                            try entry.encode(string0, forKey: .key)
                            try entry.encode(greetingstruct0, forKey: .value)
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: MapEntry<String, [String:GreetingStruct]>.CodingKeys.self, forKey: .myMap)
                        for (string0, xmlmapsnestednestedinputoutputmap0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct>.CodingKeys.self, forKey: .entry)
                            if let xmlmapsnestednestedinputoutputmap0 = xmlmapsnestednestedinputoutputmap0 {
                                try nestedMapEntryContainer0.encode(string0, forKey: .key)
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: MapEntry<String, GreetingStruct>.CodingKeys.self, forKey: .value)
                                for (string1, greetingstruct1) in xmlmapsnestednestedinputoutputmap0 {
                                    var entry = nestedMapEntryContainer1.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct>.CodingKeys.self, forKey: .entry)
                                    try entry.encode(string1, forKey: .key)
                                    try entry.encode(greetingstruct1, forKey: .value)
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
    fun `encode nested nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nestednested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedNestedInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: MapEntry<String, [String:[String:GreetingStruct]?]>.CodingKeys.self, forKey: .myMap)
                        for (string0, xmlmapsnestednestedinputoutputmap0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, [String:GreetingStruct]>.CodingKeys.self, forKey: .entry)
                            if let xmlmapsnestednestedinputoutputmap0 = xmlmapsnestednestedinputoutputmap0 {
                                try nestedMapEntryContainer0.encode(string0, forKey: .key)
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: MapEntry<String, [String:GreetingStruct]>.CodingKeys.self, forKey: .value)
                                for (string1, xmlmapsnestednestednestedinputoutputmap1) in xmlmapsnestednestedinputoutputmap0 {
                                    var nestedMapEntryContainer1 = nestedMapEntryContainer1.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct>.CodingKeys.self, forKey: .entry)
                                    if let xmlmapsnestednestednestedinputoutputmap1 = xmlmapsnestednestednestedinputoutputmap1 {
                                        try nestedMapEntryContainer1.encode(string1, forKey: .key)
                                        var nestedMapEntryContainer2 = nestedMapEntryContainer1.nestedContainer(keyedBy: MapEntry<String, GreetingStruct>.CodingKeys.self, forKey: .value)
                                        for (string2, greetingstruct2) in xmlmapsnestednestednestedinputoutputmap1 {
                                            var entry = nestedMapEntryContainer2.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct>.CodingKeys.self, forKey: .entry)
                                            try entry.encode(string2, forKey: .key)
                                            try entry.encode(greetingstruct2, forKey: .value)
                                        }
                                    }
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
    fun `encode flattened map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlFlattenedMapsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedMapsInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedUnkeyedContainer(forKey: .myMap)
                        for (string0, greetingstruct0) in myMap {
                            var entry = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct>.CodingKeys.self)
                            try entry.encode(string0, forKey: .key)
                            try entry.encode(greetingstruct0, forKey: .value)
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `encode flattened nested map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsFlattenedNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedUnkeyedContainer(forKey: .myMap)
                        for (string0, xmlmapsnestednestedinputoutputmap0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct>.CodingKeys.self)
                            if let xmlmapsnestednestedinputoutputmap0 = xmlmapsnestednestedinputoutputmap0 {
                                try nestedMapEntryContainer0.encode(string0, forKey: .key)
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: MapEntry<String, GreetingStruct>.CodingKeys.self, forKey: .value)
                                for (string1, greetingstruct1) in xmlmapsnestednestedinputoutputmap0 {
                                    var entry = nestedMapEntryContainer1.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct>.CodingKeys.self, forKey: .entry)
                                    try entry.encode(string1, forKey: .key)
                                    try entry.encode(greetingstruct1, forKey: .value)
                                }
                            }
                        }
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
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
