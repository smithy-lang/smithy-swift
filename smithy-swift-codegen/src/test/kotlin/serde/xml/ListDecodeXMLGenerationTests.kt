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

class ListDecodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameOutputBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                public init(from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.renamedListMembers) {
                        struct KeyVal0{struct item{}}
                        let renamedListMembersWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.item>.CodingKeys.self, forKey: .renamedListMembers)
                        if let renamedListMembersWrappedContainer = renamedListMembersWrappedContainer {
                            let renamedListMembersContainer = try renamedListMembersWrappedContainer.decodeIfPresent([Swift.String].self, forKey: .member)
                            var renamedListMembersBuffer:[Swift.String]? = nil
                            if let renamedListMembersContainer = renamedListMembersContainer {
                                renamedListMembersBuffer = [Swift.String]()
                                for stringContainer0 in renamedListMembersContainer {
                                    renamedListMembersBuffer?.append(stringContainer0)
                                }
                            }
                            renamedListMembers = renamedListMembersBuffer
                        } else {
                            renamedListMembers = []
                        }
                    } else {
                        renamedListMembers = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 wrapped nested list with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameNestedOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlListXmlNameNestedOutputBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case renamedListMembers = "renamed"
            }
        
            public init(from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.renamedListMembers) {
                    struct KeyVal0{struct item{}}
                    let renamedListMembersWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.item>.CodingKeys.self, forKey: .renamedListMembers)
                    if let renamedListMembersWrappedContainer = renamedListMembersWrappedContainer {
                        let renamedListMembersContainer = try renamedListMembersWrappedContainer.decodeIfPresent([[Swift.String]].self, forKey: .member)
                        var renamedListMembersBuffer:[[Swift.String]]? = nil
                        if let renamedListMembersContainer = renamedListMembersContainer {
                            renamedListMembersBuffer = [[Swift.String]]()
                            var listBuffer0: [Swift.String]? = nil
                            for listContainer0 in renamedListMembersContainer {
                                listBuffer0 = [Swift.String]()
                                for stringContainer1 in listContainer0 {
                                    listBuffer0?.append(stringContainer1)
                                }
                                if let listBuffer0 = listBuffer0 {
                                    renamedListMembersBuffer?.append(listBuffer0)
                                }
                            }
                        }
                        renamedListMembers = renamedListMembersBuffer
                    } else {
                        renamedListMembers = []
                    }
                } else {
                    renamedListMembers = nil
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 decode flattened list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/RestXml/models/XmlFlattenedListOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlFlattenedListOutputBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case myGroceryList
            }
        
            public init(from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.myGroceryList) {
                    let myGroceryListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CodingKeys.self, forKey: .myGroceryList)
                    if myGroceryListWrappedContainer != nil {
                        let myGroceryListContainer = try containerValues.decodeIfPresent([Swift.String].self, forKey: .myGroceryList)
                        var myGroceryListBuffer:[Swift.String]? = nil
                        if let myGroceryListContainer = myGroceryListContainer {
                            myGroceryListBuffer = [Swift.String]()
                            for stringContainer0 in myGroceryListContainer {
                                myGroceryListBuffer?.append(stringContainer0)
                            }
                        }
                        myGroceryList = myGroceryListBuffer
                    } else {
                        myGroceryList = []
                    }
                } else {
                    myGroceryList = nil
                }
            }
        }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 decode flattened empty list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-emptyFlattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyFlattenedListsOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlEmptyFlattenedListsOutputBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case booleanList
                case integerList
                case stringList
                case stringSet
            }
        
            public init(from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.stringList) {
                    let stringListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CodingKeys.self, forKey: .stringList)
                    if stringListWrappedContainer != nil {
                        let stringListContainer = try containerValues.decodeIfPresent([Swift.String].self, forKey: .stringList)
                        var stringListBuffer:[Swift.String]? = nil
                        if let stringListContainer = stringListContainer {
                            stringListBuffer = [Swift.String]()
                            for stringContainer0 in stringListContainer {
                                stringListBuffer?.append(stringContainer0)
                            }
                        }
                        stringList = stringListBuffer
                    } else {
                        stringList = []
                    }
                } else {
                    stringList = nil
                }
                if containerValues.contains(.stringSet) {
                    let stringSetWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CodingKeys.self, forKey: .stringSet)
                    if stringSetWrappedContainer != nil {
                        let stringSetContainer = try containerValues.decodeIfPresent([Swift.String].self, forKey: .stringSet)
                        var stringSetBuffer:Swift.Set<Swift.String>? = nil
                        if let stringSetContainer = stringSetContainer {
                            stringSetBuffer = Swift.Set<Swift.String>()
                            for stringContainer0 in stringSetContainer {
                                stringSetBuffer?.insert(stringContainer0)
                            }
                        }
                        stringSet = stringSetBuffer
                    } else {
                        stringSet = []
                    }
                } else {
                    stringSet = nil
                }
                if containerValues.contains(.integerList) {
                    struct KeyVal0{struct member{}}
                    let integerListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .integerList)
                    if let integerListWrappedContainer = integerListWrappedContainer {
                        let integerListContainer = try integerListWrappedContainer.decodeIfPresent([Swift.Int].self, forKey: .member)
                        var integerListBuffer:[Swift.Int]? = nil
                        if let integerListContainer = integerListContainer {
                            integerListBuffer = [Swift.Int]()
                            for integerContainer0 in integerListContainer {
                                integerListBuffer?.append(integerContainer0)
                            }
                        }
                        integerList = integerListBuffer
                    } else {
                        integerList = []
                    }
                } else {
                    integerList = nil
                }
                if containerValues.contains(.booleanList) {
                    struct KeyVal0{struct member{}}
                    let booleanListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .booleanList)
                    if let booleanListWrappedContainer = booleanListWrappedContainer {
                        let booleanListContainer = try booleanListWrappedContainer.decodeIfPresent([Swift.Bool].self, forKey: .member)
                        var booleanListBuffer:[Swift.Bool]? = nil
                        if let booleanListContainer = booleanListContainer {
                            booleanListBuffer = [Swift.Bool]()
                            for booleanContainer0 in booleanListContainer {
                                booleanListBuffer?.append(booleanContainer0)
                            }
                        }
                        booleanList = booleanListBuffer
                    } else {
                        booleanList = []
                    }
                } else {
                    booleanList = nil
                }
            }
        }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 decode nestednested flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedFlattenedListOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedFlattenedListOutputBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedNestedStringList
                }
            
                public init(from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.nestedNestedStringList) {
                        let nestedNestedStringListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CodingKeys.self, forKey: .nestedNestedStringList)
                        if nestedNestedStringListWrappedContainer != nil {
                            let nestedNestedStringListContainer = try containerValues.decodeIfPresent([[[Swift.String]]].self, forKey: .nestedNestedStringList)
                            var nestedNestedStringListBuffer:[[[Swift.String]]]? = nil
                            if let nestedNestedStringListContainer = nestedNestedStringListContainer {
                                nestedNestedStringListBuffer = [[[Swift.String]]]()
                                var listBuffer0: [[Swift.String]]? = nil
                                for listContainer0 in nestedNestedStringListContainer {
                                    listBuffer0 = [[Swift.String]]()
                                    var listBuffer1: [Swift.String]? = nil
                                    for listContainer1 in listContainer0 {
                                        listBuffer1 = [Swift.String]()
                                        for stringContainer2 in listContainer1 {
                                            listBuffer1?.append(stringContainer2)
                                        }
                                        if let listBuffer1 = listBuffer1 {
                                            listBuffer0?.append(listBuffer1)
                                        }
                                    }
                                    if let listBuffer0 = listBuffer0 {
                                        nestedNestedStringListBuffer?.append(listBuffer0)
                                    }
                                }
                            }
                            nestedNestedStringList = nestedNestedStringListBuffer
                        } else {
                            nestedNestedStringList = []
                        }
                    } else {
                        nestedNestedStringList = nil
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `012 decode list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListContainMapOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlListContainMapOutputBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myList
                }
            
                public init(from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myList) {
                        struct KeyVal0{struct member{}}
                        let myListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .myList)
                        if let myListWrappedContainer = myListWrappedContainer {
                            struct KeyVal0{struct key{}; struct value{}}
                            let myListContainer = try myListWrappedContainer.decodeIfPresent([ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>].self, forKey: .member)
                            var myListBuffer:[[Swift.String:Swift.String]]? = nil
                            if let myListContainer = myListContainer {
                                myListBuffer = [[Swift.String:Swift.String]]()
                                var mapBuffer0: [Swift.String:Swift.String]? = nil
                                for mapContainer0 in myListContainer {
                                    mapBuffer0 = [Swift.String:Swift.String]()
                                    if let mapContainer0NestedEntry1 = mapContainer0.entry {
                                        for stringContainer2 in mapContainer0NestedEntry1 {
                                            mapBuffer0?[stringContainer2.key] = stringContainer2.value
                                        }
                                    }
                                    if let mapBuffer0 = mapBuffer0 {
                                        myListBuffer?.append(mapBuffer0)
                                    }
                                }
                            }
                            myList = myListBuffer
                        } else {
                            myList = []
                        }
                    } else {
                        myList = nil
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `013 decode flattened list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListFlattenedContainMapOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlListFlattenedContainMapOutputBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myList
                }
            
                public init(from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.myList) {
                        let myListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CodingKeys.self, forKey: .myList)
                        if myListWrappedContainer != nil {
                            struct KeyVal0{struct key{}; struct value{}}
                            let myListContainer = try containerValues.decodeIfPresent([ClientRuntime.MapEntry<Swift.String, Swift.String, KeyVal0.key, KeyVal0.value>].self, forKey: .myList)
                            var myListBuffer:[[Swift.String:Swift.String]]? = nil
                            if let myListContainer = myListContainer {
                                myListBuffer = [[Swift.String:Swift.String]]()
                                var mapBuffer0: [Swift.String:Swift.String]? = nil
                                for mapContainer0 in myListContainer {
                                    mapBuffer0 = [Swift.String:Swift.String]()
                                    if let mapContainer0NestedEntry1 = mapContainer0.entry {
                                        for stringContainer2 in mapContainer0NestedEntry1 {
                                            mapBuffer0?[stringContainer2.key] = stringContainer2.value
                                        }
                                    }
                                    if let mapBuffer0 = mapBuffer0 {
                                        myListBuffer?.append(mapBuffer0)
                                    }
                                }
                            }
                            myList = myListBuffer
                        } else {
                            myList = []
                        }
                    } else {
                        myList = nil
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
