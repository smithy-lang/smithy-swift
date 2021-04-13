package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class MapEncodeXMLGenerationTests {
    @Test
    fun `001 encode map`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        struct KeyVal0{struct key{}; struct value{}}
                        for (stringKey0, greetingstructValue0) in myMap {
                            var entry = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: Key("entry"))
                            try entry.encode(stringKey0, forKey: .key)
                            try entry.encode(greetingstructValue0, forKey: .value)
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 encode map with name protocol`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsWithNameProtocolInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsWithNameProtocolInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case `protocol` = "protocol"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let `protocol` = `protocol` {
                        var protocolContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("protocol"))
                        struct KeyVal0{struct key{}; struct value{}}
                        for (stringKey0, greetingstructValue0) in `protocol` {
                            var entry = protocolContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: Key("entry"))
                            try entry.encode(stringKey0, forKey: .key)
                            try entry.encode(greetingstructValue0, forKey: .value)
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 encode nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        struct KeyVal0{struct key{}; struct value{}}
                        for (stringKey0, xmlmapsnestednestedinputoutputmapValue0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: Key("entry"))
                            if let xmlmapsnestednestedinputoutputmapValue0 = xmlmapsnestednestedinputoutputmapValue0 {
                                try nestedMapEntryContainer0.encode(stringKey0, forKey: .key)
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: .value)
                                struct KeyVal1{struct key{}; struct value{}}
                                for (stringKey1, greetingstructValue1) in xmlmapsnestednestedinputoutputmapValue0 {
                                    var entry = nestedMapEntryContainer1.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal1.key, KeyVal1.value>.CodingKeys.self, forKey: Key("entry"))
                                    try entry.encode(stringKey1, forKey: .key)
                                    try entry.encode(greetingstructValue1, forKey: .value)
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
    fun `004 encode nested nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nestednested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedNestedInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        struct KeyVal0{struct key{}; struct value{}}
                        for (stringKey0, xmlmapsnestednestedinputoutputmapValue0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, [String:GreetingStruct], KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: Key("entry"))
                            if let xmlmapsnestednestedinputoutputmapValue0 = xmlmapsnestednestedinputoutputmapValue0 {
                                try nestedMapEntryContainer0.encode(stringKey0, forKey: .key)
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: .value)
                                struct KeyVal1{struct key{}; struct value{}}
                                for (stringKey1, xmlmapsnestednestednestedinputoutputmapValue1) in xmlmapsnestednestedinputoutputmapValue0 {
                                    var nestedMapEntryContainer1 = nestedMapEntryContainer1.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal1.key, KeyVal1.value>.CodingKeys.self, forKey: Key("entry"))
                                    if let xmlmapsnestednestednestedinputoutputmapValue1 = xmlmapsnestednestednestedinputoutputmapValue1 {
                                        try nestedMapEntryContainer1.encode(stringKey1, forKey: .key)
                                        var nestedMapEntryContainer2 = nestedMapEntryContainer1.nestedContainer(keyedBy: Key.self, forKey: .value)
                                        struct KeyVal2{struct key{}; struct value{}}
                                        for (stringKey2, greetingstructValue2) in xmlmapsnestednestednestedinputoutputmapValue1 {
                                            var entry = nestedMapEntryContainer2.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal2.key, KeyVal2.value>.CodingKeys.self, forKey: Key("entry"))
                                            try entry.encode(stringKey2, forKey: .key)
                                            try entry.encode(greetingstructValue2, forKey: .value)
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
    fun `005 encode flattened map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlFlattenedMapsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedMapsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        if myMap.isEmpty {
                            let _ =  container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        } else {
                            var myMapContainer = container.nestedUnkeyedContainer(forKey: Key("myMap"))
                            struct KeyVal0{struct key{}; struct value{}}
                            for (stringKey0, greetingstructValue0) in myMap {
                                var entry = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self)
                                try entry.encode(stringKey0, forKey: .key)
                                try entry.encode(greetingstructValue0, forKey: .value)
                            }
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 encode flattened nested map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsFlattenedNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        if myMap.isEmpty {
                            let _ =  container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        } else {
                            var myMapContainer = container.nestedUnkeyedContainer(forKey: Key("myMap"))
                            struct KeyVal0{struct key{}; struct value{}}
                            for (stringKey0, xmlmapsnestednestedinputoutputmapValue0) in myMap {
                                var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self)
                                if let xmlmapsnestednestedinputoutputmapValue0 = xmlmapsnestednestedinputoutputmapValue0 {
                                    try nestedMapEntryContainer0.encode(stringKey0, forKey: .key)
                                    var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: .value)
                                    struct KeyVal1{struct key{}; struct value{}}
                                    for (stringKey1, greetingstructValue1) in xmlmapsnestednestedinputoutputmapValue0 {
                                        var entry = nestedMapEntryContainer1.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal1.key, KeyVal1.value>.CodingKeys.self, forKey: Key("entry"))
                                        try entry.encode(stringKey1, forKey: .key)
                                        try entry.encode(greetingstructValue1, forKey: .value)
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
    fun `007 encode map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        struct KeyVal0{struct Attribute{}; struct Setting{}}
                        for (stringKey0, greetingstructValue0) in myMap {
                            var entry = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal0.Attribute, KeyVal0.Setting>.CodingKeys.self, forKey: Key("entry"))
                            try entry.encode(stringKey0, forKey: .key)
                            try entry.encode(greetingstructValue0, forKey: .value)
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 encode map with xmlname flattened`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsXmlNameFlattenedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameFlattenedInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        if myMap.isEmpty {
                            let _ =  container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        } else {
                            var myMapContainer = container.nestedUnkeyedContainer(forKey: Key("myMap"))
                            struct KeyVal0{struct SomeCustomKey{}; struct SomeCustomValue{}}
                            for (stringKey0, greetingstructValue0) in myMap {
                                var entry = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal0.SomeCustomKey, KeyVal0.SomeCustomValue>.CodingKeys.self)
                                try entry.encode(stringKey0, forKey: .key)
                                try entry.encode(greetingstructValue0, forKey: .value)
                            }
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `009 encode map with xmlname nested`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsXmlNameNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameNestedInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        struct KeyVal0{struct CustomKey1{}; struct CustomValue1{}}
                        for (stringKey0, xmlmapsnestednestedinputoutputmapValue0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal0.CustomKey1, KeyVal0.CustomValue1>.CodingKeys.self, forKey: Key("entry"))
                            if let xmlmapsnestednestedinputoutputmapValue0 = xmlmapsnestednestedinputoutputmapValue0 {
                                try nestedMapEntryContainer0.encode(stringKey0, forKey: .key)
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: .value)
                                struct KeyVal1{struct CustomKey2{}; struct CustomValue2{}}
                                for (stringKey1, greetingstructValue1) in xmlmapsnestednestedinputoutputmapValue0 {
                                    var entry = nestedMapEntryContainer1.nestedContainer(keyedBy: MapKeyValue<String, GreetingStruct, KeyVal1.CustomKey2, KeyVal1.CustomValue2>.CodingKeys.self, forKey: Key("entry"))
                                    try entry.encode(stringKey1, forKey: .key)
                                    try entry.encode(greetingstructValue1, forKey: .value)
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
