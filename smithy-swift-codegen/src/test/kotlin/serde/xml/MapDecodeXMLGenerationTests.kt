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

class MapDecodeXMLGenerationTests {

    @Test
    fun `001 decode wrapped map`() {
        val context = setupTests("Isolated/Restxml/xml-maps.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlMapsOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case myMap
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.myMap) {
                    struct KeyVal0{struct key{}; struct value{}}
                    let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                    if let myMapWrappedContainer = myMapWrappedContainer {
                        let myMapContainer = try myMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                        var myMapBuffer: [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]? = nil
                        if let myMapContainer = myMapContainer {
                            myMapBuffer = [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]()
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsWithNameProtocolOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlMapsWithNameProtocolOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case `protocol` = "protocol"
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.`protocol`) {
                    struct KeyVal0{struct key{}; struct value{}}
                    let protocolWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .protocol)
                    if let protocolWrappedContainer = protocolWrappedContainer {
                        let protocolContainer = try protocolWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                        var protocolBuffer: [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]? = nil
                        if let protocolContainer = protocolContainer {
                            protocolBuffer = [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]()
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsNestedOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        struct KeyVal1{struct key{}; struct value{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                            var myMapBuffer: [Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]()
                                var nestedBuffer0: [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry {
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsNestedNestedOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedNestedOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        struct KeyVal1{struct key{}; struct value{}}
                        struct KeyVal2{struct key{}; struct value{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, ClientRuntime.MapEntry<Swift.String, ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal2.key, KeyVal2.value>, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, ClientRuntime.MapEntry<Swift.String, ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal2.key, KeyVal2.value>, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                            var myMapBuffer: [Swift.String:[Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:[Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]]()
                                var nestedBuffer0: [Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry {
                                        var nestedBuffer1: [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]? = nil
                                        for mapContainer1 in mapContainer0NestedEntry0 {
                                            nestedBuffer1 = [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]()
                                            if let mapContainer1NestedEntry1 = mapContainer1.value.entry {
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlFlattenedMapsOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedMapsOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.key, KeyVal0.value>].self, forKey: .myMap)
                            var myMapBuffer: [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]()
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedNestedOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        struct KeyVal1{struct key{}; struct value{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal1.key, KeyVal1.value>, KeyVal0.key, KeyVal0.value>].self, forKey: .myMap)
                            var myMapBuffer: [Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]()
                                var nestedBuffer0: [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry {
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNameOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct Attribute{}; struct Setting{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.Attribute, KeyVal0.Setting>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.Attribute, KeyVal0.Setting>].self, forKey: .entry)
                            var myMapBuffer: [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]()
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNameFlattenedOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameFlattenedOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct SomeCustomKey{}; struct SomeCustomValue{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.SomeCustomKey, KeyVal0.SomeCustomValue>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal0.SomeCustomKey, KeyVal0.SomeCustomValue>].self, forKey: .myMap)
                            var myMapBuffer: [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]()
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNameNestedOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNameNestedOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct CustomKey1{}; struct CustomValue1{}}
                        struct KeyVal1{struct CustomKey2{}; struct CustomValue2{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal1.CustomKey2, KeyVal1.CustomValue2>, KeyVal0.CustomKey1, KeyVal0.CustomValue1>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, ClientRuntime.MapEntry<Swift.String, RestXmlProtocolClientTypes.GreetingStruct, KeyVal1.CustomKey2, KeyVal1.CustomValue2>, KeyVal0.CustomKey1, KeyVal0.CustomValue1>].self, forKey: .entry)
                            var myMapBuffer: [Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:[Swift.String:RestXmlProtocolClientTypes.GreetingStruct]]()
                                var nestedBuffer0: [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [Swift.String:RestXmlProtocolClientTypes.GreetingStruct]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry {
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedNestedXmlNameOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedXmlNameOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct yek{}; struct eulav{}}
                        struct KeyVal1{struct K{}; struct V{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal1.K, KeyVal1.V>, KeyVal0.yek, KeyVal0.eulav>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal1.K, KeyVal1.V>, KeyVal0.yek, KeyVal0.eulav>].self, forKey: .myMap)
                            var myMapBuffer: [Swift.String:[Swift.String:Swift.String]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:[Swift.String:Swift.String]]()
                                var nestedBuffer0: [Swift.String:Swift.String]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [Swift.String:Swift.String]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry {
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsXmlNamespaceOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsXmlNamespaceOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct Quality{}; struct Degree{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal0.Quality, KeyVal0.Degree>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, Swift.String, KeyVal0.Quality, KeyVal0.Degree>].self, forKey: .entry)
                            var myMapBuffer: [Swift.String:Swift.String]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:Swift.String]()
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedXmlNamespaceOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedXmlNamespaceOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct Uid{}; struct Val{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal0.Uid, KeyVal0.Val>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, Swift.String, KeyVal0.Uid, KeyVal0.Val>].self, forKey: .myMap)
                            var myMapBuffer: [Swift.String:Swift.String]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:Swift.String]()
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsNestedXmlNamespaceOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsNestedXmlNamespaceOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct yek{}; struct eulav{}}
                        struct KeyVal1{struct K{}; struct V{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal1.K, KeyVal1.V>, KeyVal0.yek, KeyVal0.eulav>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal1.K, KeyVal1.V>, KeyVal0.yek, KeyVal0.eulav>].self, forKey: .entry)
                            var myMapBuffer: [Swift.String:[Swift.String:Swift.String]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:[Swift.String:Swift.String]]()
                                var nestedBuffer0: [Swift.String:Swift.String]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [Swift.String:Swift.String]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry {
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
    fun `014 decode nested flattened map with xmlnamespace`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-nested-namespace.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedNestedXmlNamespaceOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedNestedXmlNamespaceOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct yek{}; struct eulav{}}
                        struct KeyVal1{struct K{}; struct V{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal1.K, KeyVal1.V>, KeyVal0.yek, KeyVal0.eulav>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal1.K, KeyVal1.V>, KeyVal0.yek, KeyVal0.eulav>].self, forKey: .myMap)
                            var myMapBuffer: [Swift.String:[Swift.String:Swift.String]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:[Swift.String:Swift.String]]()
                                var nestedBuffer0: [Swift.String:Swift.String]? = nil
                                for mapContainer0 in myMapContainer {
                                    nestedBuffer0 = [Swift.String:Swift.String]()
                                    if let mapContainer0NestedEntry0 = mapContainer0.value.entry {
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
    fun `015 decode map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsContainListOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsContainListOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        struct KeyVal1{struct member{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, ClientRuntime.CollectionMember<Swift.String, KeyVal1.member>, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, ClientRuntime.CollectionMember<Swift.String, KeyVal1.member>, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                            var myMapBuffer: [Swift.String:[Swift.String]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:[Swift.String]]()
                                var nestedBuffer0: [Swift.String]? = nil
                                for listContainer0 in myMapContainer {
                                    nestedBuffer0 = [Swift.String]()
                                    for stringContainer0 in listContainer0.value.member {
                                        nestedBuffer0?.append(stringContainer0)
                                    }
                                    myMapBuffer?[listContainer0.key] = nestedBuffer0
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
    fun `016 decode flattened map containing list`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-contain-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedContainListOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedContainListOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        struct KeyVal1{struct member{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, ClientRuntime.CollectionMember<Swift.String, KeyVal1.member>, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if myMapWrappedContainer != nil {
                            let myMapContainer = try containerValues.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, ClientRuntime.CollectionMember<Swift.String, KeyVal1.member>, KeyVal0.key, KeyVal0.value>].self, forKey: .myMap)
                            var myMapBuffer: [Swift.String:[Swift.String]]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:[Swift.String]]()
                                var nestedBuffer0: [Swift.String]? = nil
                                for listContainer0 in myMapContainer {
                                    nestedBuffer0 = [Swift.String]()
                                    for stringContainer0 in listContainer0.value.member {
                                        nestedBuffer0?.append(stringContainer0)
                                    }
                                    myMapBuffer?[listContainer0.key] = nestedBuffer0
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
    fun `017 decode map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsTimestampsOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsTimestampsOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case timestampMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.timestampMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        let timestampMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .timestampMap)
                        if let timestampMapWrappedContainer = timestampMapWrappedContainer {
                            let timestampMapContainer = try timestampMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                            var timestampMapBuffer: [Swift.String:ClientRuntime.Date]? = nil
                            if let timestampMapContainer = timestampMapContainer {
                                timestampMapBuffer = [Swift.String:ClientRuntime.Date]()
                                for timestampContainer0 in timestampMapContainer {
                                    timestampMapBuffer?[timestampContainer0.key] = try timestampMapWrappedContainer.timestampStringAsDate(timestampContainer0.value, format: .epochSeconds, forKey: .timestampMap)
                                }
                            }
                            timestampMap = timestampMapBuffer
                        } else {
                            timestampMap = [:]
                        }
                    } else {
                        timestampMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `018 decode flattened map containing timestamp`() {
        val context = setupTests("Isolated/Restxml/xml-maps-flattened-timestamp.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsFlattenedTimestampsOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsFlattenedTimestampsOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case timestampMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.timestampMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        let timestampMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .timestampMap)
                        if timestampMapWrappedContainer != nil {
                            let timestampMapContainer = try containerValues.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>].self, forKey: .timestampMap)
                            var timestampMapBuffer: [Swift.String:ClientRuntime.Date]? = nil
                            if let timestampMapContainer = timestampMapContainer {
                                timestampMapBuffer = [Swift.String:ClientRuntime.Date]()
                                for timestampContainer0 in timestampMapContainer {
                                    timestampMapBuffer?[timestampContainer0.key] = try timestampMapWrappedContainer.timestampStringAsDate(timestampContainer0.value, format: .epochSeconds, forKey: .timestampMap)
                                }
                            }
                            timestampMap = timestampMapBuffer
                        } else {
                            timestampMap = [:]
                        }
                    } else {
                        timestampMap = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `019 two maps that may conflict with KeyValue`() {
        val context = setupTests("Isolated/Restxml/xml-maps-2x.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlMapsTwoOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlMapsTwoOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myMap
                    case mySecondMap
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        let myMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .myMap)
                        if let myMapWrappedContainer = myMapWrappedContainer {
                            let myMapContainer = try myMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                            var myMapBuffer: [Swift.String:Swift.String]? = nil
                            if let myMapContainer = myMapContainer {
                                myMapBuffer = [Swift.String:Swift.String]()
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
                    if containerValues.contains(.mySecondMap) {
                        struct KeyVal0{struct key{}; struct value{}}
                        let mySecondMapWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>.CodingKeys.self, forKey: .mySecondMap)
                        if let mySecondMapWrappedContainer = mySecondMapWrappedContainer {
                            let mySecondMapContainer = try mySecondMapWrappedContainer.decodeIfPresent([ClientRuntime.MapKeyValue<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>].self, forKey: .entry)
                            var mySecondMapBuffer: [Swift.String:Swift.String]? = nil
                            if let mySecondMapContainer = mySecondMapContainer {
                                mySecondMapBuffer = [Swift.String:Swift.String]()
                                for stringContainer0 in mySecondMapContainer {
                                    mySecondMapBuffer?[stringContainer0.key] = stringContainer0.value
                                }
                            }
                            mySecondMap = mySecondMapBuffer
                        } else {
                            mySecondMap = [:]
                        }
                    } else {
                        mySecondMap = nil
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
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
