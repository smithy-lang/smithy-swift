package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class MapDecodeXMLGenerationTests {

    @Test
    fun `001 decode wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlMapsOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case myMap
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                struct KeyVal0{struct key{}; struct value{}}
                if containerValues.contains(.myMap) {
                    let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                    if let myMapWrappedContainer = myMapWrappedContainer {
                        let myMapContainer = try myMapWrappedContainer.decodeIfPresent([MapKeyValue<String, GreetingStruct, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                        var myMapBuffer: [String:GreetingStruct]? = nil
                        if let myMapContainer = myMapContainer {
                            myMapBuffer = [String:GreetingStruct]()
                            for structureContainer0 in myMapContainer {
                                myMapBuffer?[structureContainer0.key] = structureContainer0.value
                            }
                        }
                        myMap = myMapBuffer
                    } else {
                        myMap = [:]
                    }
                } else {
                    myMap = nil
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 decode wrapped map with name protocol`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsWithNameProtocolOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlMapsWithNameProtocolOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case `protocol` = "protocol"
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                struct KeyVal0{struct key{}; struct value{}}
                if containerValues.contains(.`protocol`) {
                    let protocolWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .protocol)
                    if let protocolWrappedContainer = protocolWrappedContainer {
                        let protocolContainer = try protocolWrappedContainer.decodeIfPresent([MapKeyValue<String, GreetingStruct, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                        var protocolBuffer: [String:GreetingStruct]? = nil
                        if let protocolContainer = protocolContainer {
                            protocolBuffer = [String:GreetingStruct]()
                            for structureContainer0 in protocolContainer {
                                protocolBuffer?[structureContainer0.key] = structureContainer0.value
                            }
                        }
                        `protocol` = protocolBuffer
                    } else {
                        `protocol` = [:]
                    }
                } else {
                    `protocol` = nil
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 decode nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct key{}; struct value{}}
                    struct KeyVal1{struct key{}; struct value{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, MapEntry<String, GreetingStruct, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([MapKeyValue<String, MapEntry<String, GreetingStruct, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                            var myMapBuffer: [String:[String:GreetingStruct]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:[String:GreetingStruct]]()
                                var nestedBuffer0: [String:GreetingStruct]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [String:GreetingStruct]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry  {
                                        for structureContainer1 in mapContainer0NestedEntry0 {
                                            nestedBuffer0?[structureContainer1.key] = structureContainer1.value
                                        }
                                    }
                                    myMapBuffer?[mapContainer0.key] = nestedBuffer0
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 decode nested nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nestednested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedNestedOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedNestedOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct key{}; struct value{}}
                    struct KeyVal1{struct key{}; struct value{}}
                    struct KeyVal2{struct key{}; struct value{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, MapEntry<String, MapEntry<String, GreetingStruct, KeyVal2.key, KeyVal2.value>, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([MapKeyValue<String, MapEntry<String, MapEntry<String, GreetingStruct, KeyVal2.key, KeyVal2.value>, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                            var myMapBuffer: [String:[String:[String:GreetingStruct]?]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:[String:[String:GreetingStruct]?]]()
                                var nestedBuffer0: [String:[String:GreetingStruct]?]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [String:[String:GreetingStruct]?]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry  {
                                        var nestedBuffer1: [String:GreetingStruct]? = nil
                                        for mapContainer1 in mapContainer0NestedEntry0 {
                                            nestedBuffer1 = [String:GreetingStruct]()
                                            if let mapContainer1NestedEntry1 = mapContainer1.value.entry  {
                                                for structureContainer2 in mapContainer1NestedEntry1 {
                                                    nestedBuffer1?[structureContainer2.key] = structureContainer2.value
                                                }
                                            }
                                            nestedBuffer0?[mapContainer1.key] = nestedBuffer1
                                        }
                                    }
                                    myMapBuffer?[mapContainer0.key] = nestedBuffer0
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 decode flattened map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlFlattenedMapsOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedMapsOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct key{}; struct value{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([MapKeyValue<String, GreetingStruct, KeyVal0.key, KeyVal0.value>].self, forKey: .myMap)
                            var myMapBuffer: [String:GreetingStruct]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:GreetingStruct]()
                                for structureContainer0 in myMapContainer {
                                    myMapBuffer?[structureContainer0.key] = structureContainer0.value
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 decode flattened nested map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsFlattenedNestedOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct key{}; struct value{}}
                    struct KeyVal1{struct key{}; struct value{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, MapEntry<String, GreetingStruct, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([MapKeyValue<String, MapEntry<String, GreetingStruct, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>].self, forKey: .myMap)
                            var myMapBuffer: [String:[String:GreetingStruct]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:[String:GreetingStruct]]()
                                var nestedBuffer0: [String:GreetingStruct]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [String:GreetingStruct]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry  {
                                        for structureContainer1 in mapContainer0NestedEntry0 {
                                            nestedBuffer0?[structureContainer1.key] = structureContainer1.value
                                        }
                                    }
                                    myMapBuffer?[mapContainer0.key] = nestedBuffer0
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 decode map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsXmlNameOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct Attribute{}; struct Setting{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, GreetingStruct, KeyVal0.Attribute, KeyVal0.Setting>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([MapKeyValue<String, GreetingStruct, KeyVal0.Attribute, KeyVal0.Setting>].self, forKey: .entry)
                            var myMapBuffer: [String:GreetingStruct]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:GreetingStruct]()
                                for structureContainer0 in myMapContainer {
                                    myMapBuffer?[structureContainer0.key] = structureContainer0.value
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 decode map with xmlname flattened`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsXmlNameFlattenedOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameFlattenedOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct SomeCustomKey{}; struct SomeCustomValue{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, GreetingStruct, KeyVal0.SomeCustomKey, KeyVal0.SomeCustomValue>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([MapKeyValue<String, GreetingStruct, KeyVal0.SomeCustomKey, KeyVal0.SomeCustomValue>].self, forKey: .myMap)
                            var myMapBuffer: [String:GreetingStruct]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:GreetingStruct]()
                                for structureContainer0 in myMapContainer {
                                    myMapBuffer?[structureContainer0.key] = structureContainer0.value
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `009 decode map with xmlname nested`() {
        val context = setupTests("Isolated/Restxml/xml-maps-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsXmlNameNestedOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameNestedOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct CustomKey1{}; struct CustomValue1{}}
                    struct KeyVal1{struct CustomKey2{}; struct CustomValue2{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, MapEntry<String, GreetingStruct, KeyVal1.CustomKey2, KeyVal1.CustomValue2>, KeyVal0.CustomKey1, KeyVal0.CustomValue1>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([MapKeyValue<String, MapEntry<String, GreetingStruct, KeyVal1.CustomKey2, KeyVal1.CustomValue2>, KeyVal0.CustomKey1, KeyVal0.CustomValue1>].self, forKey: .entry)
                            var myMapBuffer: [String:[String:GreetingStruct]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:[String:GreetingStruct]]()
                                var nestedBuffer0: [String:GreetingStruct]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [String:GreetingStruct]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry  {
                                        for structureContainer1 in mapContainer0NestedEntry0 {
                                            nestedBuffer0?[structureContainer1.key] = structureContainer1.value
                                        }
                                    }
                                    myMapBuffer?[mapContainer0.key] = nestedBuffer0
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `011 decode flattened nested map with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsFlattenedNestedXmlNameOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedXmlNameOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct yek{}; struct eulav{}}
                    struct KeyVal1{struct K{}; struct V{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, MapEntry<String, String, KeyVal1.K, KeyVal1.V>, KeyVal0.yek, KeyVal0.eulav>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([MapKeyValue<String, MapEntry<String, String, KeyVal1.K, KeyVal1.V>, KeyVal0.yek, KeyVal0.eulav>].self, forKey: .myMap)
                            var myMapBuffer: [String:[String:String]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:[String:String]]()
                                var nestedBuffer0: [String:String]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [String:String]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry  {
                                        for stringContainer1 in mapContainer0NestedEntry0 {
                                            nestedBuffer0?[stringContainer1.key] = stringContainer1.value
                                        }
                                    }
                                    myMapBuffer?[mapContainer0.key] = nestedBuffer0
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 decode map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsXmlNamespaceOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNamespaceOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct Quality{}; struct Degree{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, String, KeyVal0.Quality, KeyVal0.Degree>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([MapKeyValue<String, String, KeyVal0.Quality, KeyVal0.Degree>].self, forKey: .entry)
                            var myMapBuffer: [String:String]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:String]()
                                for stringContainer0 in myMapContainer {
                                    myMapBuffer?[stringContainer0.key] = stringContainer0.value
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `012 decode flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsFlattenedXmlNamespaceOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedXmlNamespaceOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    struct KeyVal0{struct Uid{}; struct Val{}}
                    if containerValues.contains(.myMap) {
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: MapEntry<String, String, KeyVal0.Uid, KeyVal0.Val>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([MapKeyValue<String, String, KeyVal0.Uid, KeyVal0.Val>].self, forKey: .myMap)
                            var myMapBuffer: [String:String]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [String:String]()
                                for stringContainer0 in myMapContainer {
                                    myMapBuffer?[stringContainer0.key] = stringContainer0.value
                                }
                            }
                            myMap = myMapBuffer
                        } else {
                            myMap = [:]
                        }
                    } else {
                        myMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `013 decode nested map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedNamespaceOutputBody+Decodable.swift")
        val expectedContents =
            """
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `014 decode nested flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsFlattenedXmlNamespaceInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """

            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
