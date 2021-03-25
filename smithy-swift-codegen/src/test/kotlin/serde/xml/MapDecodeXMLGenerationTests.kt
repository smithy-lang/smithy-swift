package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class MapDecodeXMLGenerationTests {

    @Test
    fun `decode wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlMapsOutputBody: Decodable {
            private enum CodingKeys: String, CodingKey {
                case myMap
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                let myMapWrappedContainer = try containerValues.nestedContainer(keyedBy: MapEntry<String, GreetingStruct>.CodingKeys.self, forKey: .myMap)
                let myMapContainer = try myMapWrappedContainer.decodeIfPresent([MapKeyValue<String, GreetingStruct>].self, forKey: .entry)
                var myMapBuffer: [String:GreetingStruct]? = nil
                if let myMapContainer = myMapContainer {
                    myMapBuffer = [String:GreetingStruct]()
                    for structureContainer0 in myMapContainer {
                        myMapBuffer?[structureContainer0.key] = structureContainer0.value
                    }
                }
                myMap = myMapBuffer
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode wrapped map with name protocol`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsWithNameProtocolOutputBody+Decodable.swift")
        val expectedContents = """
            extension XmlMapsWithNameProtocolOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case `protocol` = "protocol"
                }

                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let protocolWrappedContainer = try containerValues.nestedContainer(keyedBy: MapEntry<String, GreetingStruct>.CodingKeys.self, forKey: .protocol)
                    let protocolContainer = try protocolWrappedContainer.decodeIfPresent([MapKeyValue<String, GreetingStruct>].self, forKey: .entry)
                    var protocolBuffer: [String:GreetingStruct]? = nil
                    if let protocolContainer = protocolContainer {
                        protocolBuffer = [String:GreetingStruct]()
                        for structureContainer0 in protocolContainer {
                            protocolBuffer?[structureContainer0.key] = structureContainer0.value
                        }
                    }
                    `protocol` = protocolBuffer
                }
            }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let myMapWrappedContainer = try containerValues.nestedContainer(keyedBy: MapEntry<String, MapEntry<String, GreetingStruct>>.CodingKeys.self, forKey: .myMap)
                    let myMapContainer = try myMapWrappedContainer.decodeIfPresent([MapKeyValue<String, MapEntry<String, GreetingStruct>>].self, forKey: .entry)
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
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `decode nested nested wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps-nestednested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlMapsNestedNestedOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedNestedOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case myMap
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let myMapWrappedContainer = try containerValues.nestedContainer(keyedBy: MapEntry<String, MapEntry<String, MapEntry<String, GreetingStruct>>>.CodingKeys.self, forKey: .myMap)
                    let myMapContainer = try myMapWrappedContainer.decodeIfPresent([MapKeyValue<String, MapEntry<String, MapEntry<String, GreetingStruct>>>].self, forKey: .entry)
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
                }
            }
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
