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
        val contents = getFileContents(context.manifest, "/example/models/XmlListXmlNameOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.renamedListMembers) {
                        struct KeyVal0{struct item{}}
                        let renamedListMembersWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.item>.CodingKeys.self, forKey: .renamedListMembers)
                        if let renamedListMembersWrappedContainer = renamedListMembersWrappedContainer {
                            let renamedListMembersContainer = try renamedListMembersWrappedContainer.decodeIfPresent([String].self, forKey: .member)
                            var renamedListMembersBuffer:[String]? = nil
                            if let renamedListMembersContainer = renamedListMembersContainer {
                                renamedListMembersBuffer = [String]()
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
        val contents = getFileContents(context.manifest, "/example/models/XmlListXmlNameNestedOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlListXmlNameNestedOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case renamedListMembers = "renamed"
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.renamedListMembers) {
                    struct KeyVal0{struct item{}}
                    let renamedListMembersWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.item>.CodingKeys.self, forKey: .renamedListMembers)
                    if let renamedListMembersWrappedContainer = renamedListMembersWrappedContainer {
                        let renamedListMembersContainer = try renamedListMembersWrappedContainer.decodeIfPresent([[String]?].self, forKey: .member)
                        var renamedListMembersBuffer:[[String]?]? = nil
                        if let renamedListMembersContainer = renamedListMembersContainer {
                            renamedListMembersBuffer = [[String]?]()
                            for listContainer0 in renamedListMembersContainer {
                                var listBuffer0 = [String]()
                                if let listContainer0 = listContainer0 {
                                    for stringContainer1 in listContainer0 {
                                        listBuffer0.append(stringContainer1)
                                    }
                                }
                                renamedListMembersBuffer?.append(listBuffer0)
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

        val contents = getFileContents(context.manifest, "/example/models/XmlFlattenedListOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlFlattenedListOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case myGroceryList
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.myGroceryList) {
                    let myGroceryListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<Key>.CodingKeys.self, forKey: .myGroceryList)
                    if myGroceryListWrappedContainer != nil {
                        let myGroceryListContainer = try containerValues.decodeIfPresent([String].self, forKey: .myGroceryList)
                        var myGroceryListBuffer:[String]? = nil
                        if let myGroceryListContainer = myGroceryListContainer {
                            myGroceryListBuffer = [String]()
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
        val contents = getFileContents(context.manifest, "/example/models/XmlEmptyFlattenedListsOutputBody+Decodable.swift")
        val expectedContents = """
        extension XmlEmptyFlattenedListsOutputBody: Decodable {
            enum CodingKeys: String, CodingKey {
                case booleanList
                case integerList
                case stringList
                case stringSet
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.stringList) {
                    let stringListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<Key>.CodingKeys.self, forKey: .stringList)
                    if stringListWrappedContainer != nil {
                        let stringListContainer = try containerValues.decodeIfPresent([String].self, forKey: .stringList)
                        var stringListBuffer:[String]? = nil
                        if let stringListContainer = stringListContainer {
                            stringListBuffer = [String]()
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
                    let stringSetWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<Key>.CodingKeys.self, forKey: .stringSet)
                    if stringSetWrappedContainer != nil {
                        let stringSetContainer = try containerValues.decodeIfPresent([String].self, forKey: .stringSet)
                        var stringSetBuffer:Set<String>? = nil
                        if let stringSetContainer = stringSetContainer {
                            stringSetBuffer = Set<String>()
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
                    let integerListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.member>.CodingKeys.self, forKey: .integerList)
                    if let integerListWrappedContainer = integerListWrappedContainer {
                        let integerListContainer = try integerListWrappedContainer.decodeIfPresent([Int].self, forKey: .member)
                        var integerListBuffer:[Int]? = nil
                        if let integerListContainer = integerListContainer {
                            integerListBuffer = [Int]()
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
                    let booleanListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<KeyVal0.member>.CodingKeys.self, forKey: .booleanList)
                    if let booleanListWrappedContainer = booleanListWrappedContainer {
                        let booleanListContainer = try booleanListWrappedContainer.decodeIfPresent([Bool].self, forKey: .member)
                        var booleanListBuffer:[Bool]? = nil
                        if let booleanListContainer = booleanListContainer {
                            booleanListBuffer = [Bool]()
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
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedNestedFlattenedListOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedFlattenedListOutputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.nestedNestedStringList) {
                        let nestedNestedStringListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMember<Key>.CodingKeys.self, forKey: .nestedNestedStringList)
                        if nestedNestedStringListWrappedContainer != nil {
                            let nestedNestedStringListContainer = try containerValues.decodeIfPresent([[[String]?]?].self, forKey: .nestedNestedStringList)
                            var nestedNestedStringListBuffer:[[[String]?]?]? = nil
                            if let nestedNestedStringListContainer = nestedNestedStringListContainer {
                                nestedNestedStringListBuffer = [[[String]?]?]()
                                for listContainer0 in nestedNestedStringListContainer {
                                    var listBuffer0 = [[String]?]()
                                    if let listContainer0 = listContainer0 {
                                        for listContainer1 in listContainer0 {
                                            var listBuffer1 = [String]()
                                            if let listContainer1 = listContainer1 {
                                                for stringContainer2 in listContainer1 {
                                                    listBuffer1.append(stringContainer2)
                                                }
                                            }
                                            listBuffer0.append(listBuffer1)
                                        }
                                    }
                                    nestedNestedStringListBuffer?.append(listBuffer0)
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
    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
