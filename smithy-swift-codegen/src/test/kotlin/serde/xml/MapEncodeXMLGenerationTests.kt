package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import listFilesFromManifest
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
                        for (stringKey0, greetingstructValue0) in myMap {
                            var entry = myMapContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                            var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try keyContainer.encode(stringKey0, forKey: Key(""))
                            var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                            try valueContainer.encode(greetingstructValue0, forKey: Key(""))
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
                        for (stringKey0, greetingstructValue0) in `protocol` {
                            var entry = protocolContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                            var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try keyContainer.encode(stringKey0, forKey: Key(""))
                            var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                            try valueContainer.encode(greetingstructValue0, forKey: Key(""))
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
                        for (stringKey0, xmlmapsnestednestedinputoutputmapValue0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                            var nestedKeyContainer0 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try nestedKeyContainer0.encode(stringKey0, forKey: Key(""))
                            if let xmlmapsnestednestedinputoutputmapValue0 = xmlmapsnestednestedinputoutputmapValue0 {
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                for (stringKey1, greetingstructValue1) in xmlmapsnestednestedinputoutputmapValue0 {
                                    var entry = nestedMapEntryContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                                    var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                                    try keyContainer.encode(stringKey1, forKey: Key(""))
                                    var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                    try valueContainer.encode(greetingstructValue1, forKey: Key(""))
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
                        for (stringKey0, xmlmapsnestednestedinputoutputmapValue0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                            var nestedKeyContainer0 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try nestedKeyContainer0.encode(stringKey0, forKey: Key(""))
                            if let xmlmapsnestednestedinputoutputmapValue0 = xmlmapsnestednestedinputoutputmapValue0 {
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                for (stringKey1, xmlmapsnestednestednestedinputoutputmapValue1) in xmlmapsnestednestedinputoutputmapValue0 {
                                    var nestedMapEntryContainer1 = nestedMapEntryContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                                    var nestedKeyContainer1 = nestedMapEntryContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                                    try nestedKeyContainer1.encode(stringKey1, forKey: Key(""))
                                    if let xmlmapsnestednestednestedinputoutputmapValue1 = xmlmapsnestednestednestedinputoutputmapValue1 {
                                        var nestedMapEntryContainer2 = nestedMapEntryContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                        for (stringKey2, greetingstructValue2) in xmlmapsnestednestednestedinputoutputmapValue1 {
                                            var entry = nestedMapEntryContainer2.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                                            var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                                            try keyContainer.encode(stringKey2, forKey: Key(""))
                                            var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                            try valueContainer.encode(greetingstructValue2, forKey: Key(""))
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
                            for (stringKey0, greetingstructValue0) in myMap {
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                                var keyContainer = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                                try keyContainer.encode(stringKey0, forKey: Key(""))
                                var valueContainer = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                try valueContainer.encode(greetingstructValue0, forKey: Key(""))
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
                            for (stringKey0, xmlmapsnestednestedinputoutputmapValue0) in myMap {
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                                if let xmlmapsnestednestedinputoutputmapValue0 = xmlmapsnestednestedinputoutputmapValue0 {
                                    var nestedKeyContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                                    try nestedKeyContainer0.encode(stringKey0, forKey: Key(""))
                                    var nestedValueContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                    for (stringKey1, greetingstructValue1) in xmlmapsnestednestedinputoutputmapValue0 {
                                        var nestedContainer1 = nestedValueContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                                        var keyContainer = nestedContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                                        try keyContainer.encode(stringKey1, forKey: Key(""))
                                        var valueContainer = nestedContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                        try valueContainer.encode(greetingstructValue1, forKey: Key(""))
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
                        for (stringKey0, greetingstructValue0) in myMap {
                            var entry = myMapContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                            var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("Attribute"))
                            try keyContainer.encode(stringKey0, forKey: Key(""))
                            var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("Setting"))
                            try valueContainer.encode(greetingstructValue0, forKey: Key(""))
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
                            for (stringKey0, greetingstructValue0) in myMap {
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                                var keyContainer = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("SomeCustomKey"))
                                try keyContainer.encode(stringKey0, forKey: Key(""))
                                var valueContainer = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("SomeCustomValue"))
                                try valueContainer.encode(greetingstructValue0, forKey: Key(""))
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
                        for (stringKey0, xmlmapsnestednestedinputoutputmapValue0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                            var nestedKeyContainer0 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("CustomKey1"))
                            try nestedKeyContainer0.encode(stringKey0, forKey: Key(""))
                            if let xmlmapsnestednestedinputoutputmapValue0 = xmlmapsnestednestedinputoutputmapValue0 {
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("CustomValue1"))
                                for (stringKey1, greetingstructValue1) in xmlmapsnestednestedinputoutputmapValue0 {
                                    var entry = nestedMapEntryContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                                    var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("CustomKey2"))
                                    try keyContainer.encode(stringKey1, forKey: Key(""))
                                    var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("CustomValue2"))
                                    try valueContainer.encode(greetingstructValue1, forKey: Key(""))
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
    fun `010 encode flattened nested map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsFlattenedNestedXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedXmlNameInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        if myMap.isEmpty {
                            let _ =  container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        } else {
                            for (stringKey0, xmlmapsnestednestedinputoutputmapValue0) in myMap {
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                                if let xmlmapsnestednestedinputoutputmapValue0 = xmlmapsnestednestedinputoutputmapValue0 {
                                    var nestedKeyContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("yek"))
                                    try nestedKeyContainer0.encode(stringKey0, forKey: Key(""))
                                    var nestedValueContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("eulav"))
                                    for (stringKey1, stringValue1) in xmlmapsnestednestedinputoutputmapValue0 {
                                        var nestedContainer1 = nestedValueContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                                        var keyContainer = nestedContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("K"))
                                        try keyContainer.encode(stringKey1, forKey: Key(""))
                                        var valueContainer = nestedContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("V"))
                                        try valueContainer.encode(stringValue1, forKey: Key(""))
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
    fun `011 encode map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsXmlNamespaceInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNamespaceInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://aoo.com", forKey: Key("xmlns"))
                    }
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        try myMapContainer.encode("http://boo.com", forKey: Key("xmlns"))
                        for (stringKey0, stringValue0) in myMap {
                            var entry = myMapContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                            var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("Quality"))
                            try keyContainer.encode("http://doo.com", forKey: Key("xmlns"))
                            try keyContainer.encode(stringKey0, forKey: Key(""))
                            var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("Degree"))
                            try valueContainer.encode("http://eoo.com", forKey: Key("xmlns"))
                            try valueContainer.encode(stringValue0, forKey: Key(""))
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `012 encode flattened map xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsFlattenedXmlNamespaceInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedXmlNamespaceInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://aoo.com", forKey: Key("xmlns"))
                    }
                    if let myMap = myMap {
                        if myMap.isEmpty {
                            let _ =  container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        } else {
                            for (stringKey0, stringValue0) in myMap {
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                                try nestedContainer0.encode("http://boo.com", forKey: Key("xmlns"))
                                var keyContainer = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("Uid"))
                                try keyContainer.encode("http://doo.com", forKey: Key("xmlns"))
                                try keyContainer.encode(stringKey0, forKey: Key(""))
                                var valueContainer = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("Val"))
                                try valueContainer.encode("http://eoo.com", forKey: Key("xmlns"))
                                try valueContainer.encode(stringValue0, forKey: Key(""))
                            }
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `013 encode nested map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedXmlNamespaceInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedXmlNamespaceInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://aoo.com", forKey: Key("xmlns"))
                    }
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        try myMapContainer.encode("http://boo.com", forKey: Key("xmlns"))
                        for (stringKey0, xmlmapsnestednestedxmlnamespaceinputoutputmapValue0) in myMap {
                            var nestedMapEntryContainer0 = myMapContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                            var nestedKeyContainer0 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("yek"))
                            try nestedKeyContainer0.encode("http://doo.com", forKey: Key("xmlns"))
                            try nestedKeyContainer0.encode(stringKey0, forKey: Key(""))
                            if let xmlmapsnestednestedxmlnamespaceinputoutputmapValue0 = xmlmapsnestednestedxmlnamespaceinputoutputmapValue0 {
                                var nestedMapEntryContainer1 = nestedMapEntryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("eulav"))
                                try nestedMapEntryContainer1.encode("http://eoo.com", forKey: Key("xmlns"))
                                for (stringKey1, stringValue1) in xmlmapsnestednestedxmlnamespaceinputoutputmapValue0 {
                                    var entry = nestedMapEntryContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                                    var keyContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("K"))
                                    try keyContainer.encode("http://goo.com", forKey: Key("xmlns"))
                                    try keyContainer.encode(stringKey1, forKey: Key(""))
                                    var valueContainer = entry.nestedContainer(keyedBy: Key.self, forKey: Key("V"))
                                    try valueContainer.encode("http://hoo.com", forKey: Key("xmlns"))
                                    try valueContainer.encode(stringValue1, forKey: Key(""))
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
    fun `014 encode nested flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsFlattenedNestedXmlNamespaceInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedXmlNamespaceInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if encoder.codingPath.isEmpty {
                        try container.encode("http://aoo.com", forKey: Key("xmlns"))
                    }
                    if let myMap = myMap {
                        if myMap.isEmpty {
                            let _ =  container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        } else {
                            for (stringKey0, xmlmapsnestednestednamespaceinputoutputmapValue0) in myMap {
                                var nestedContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                                if let xmlmapsnestednestednamespaceinputoutputmapValue0 = xmlmapsnestednestednamespaceinputoutputmapValue0 {
                                    var nestedKeyContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("yek"))
                                    try nestedKeyContainer0.encode("http://doo.com", forKey: Key("xmlns"))
                                    try nestedKeyContainer0.encode(stringKey0, forKey: Key(""))
                                    var nestedValueContainer0 = nestedContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("eulav"))
                                    try nestedValueContainer0.encode("http://eoo.com", forKey: Key("xmlns"))
                                    for (stringKey1, stringValue1) in xmlmapsnestednestednamespaceinputoutputmapValue0 {
                                        var nestedContainer1 = nestedValueContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                                        var keyContainer = nestedContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("K"))
                                        try keyContainer.encode("http://goo.com", forKey: Key("xmlns"))
                                        try keyContainer.encode(stringKey1, forKey: Key(""))
                                        var valueContainer = nestedContainer1.nestedContainer(keyedBy: Key.self, forKey: Key("V"))
                                        try valueContainer.encode("http://hoo.com", forKey: Key("xmlns"))
                                        try valueContainer.encode(stringValue1, forKey: Key(""))
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
    fun `015 encode map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsContainListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlMapsContainListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myMap = myMap {
                        var myMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("myMap"))
                        for (stringKey0, xmlsimplestringlistValue0) in myMap {
                            var entryContainer0 = myMapContainer.nestedContainer(keyedBy: Key.self, forKey: Key("entry"))
                            var keyContainer = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("key"))
                            try keyContainer.encode(stringKey0, forKey: Key(""))
                            if let xmlsimplestringlistValue0 = xmlsimplestringlistValue0 {
                                var valueContainer = entryContainer0.nestedContainer(keyedBy: Key.self, forKey: Key("value"))
                                for string0 in xmlsimplestringlistValue0 {
                                    try valueContainer.encode(string0, forKey: Key("member"))
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
