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

class StructDecodeXMLGenerationTests {
    @Test
    fun `XmlWrappedListOutputResponseBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-lists-wrapped.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/RestXml/models/XmlWrappedListOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlWrappedListOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case myGroceryList
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.myGroceryList) {
                    struct KeyVal0{struct member{}}
                    let myGroceryListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .myGroceryList)
                    if let myGroceryListWrappedContainer = myGroceryListWrappedContainer {
                        let myGroceryListContainer = try myGroceryListWrappedContainer.decodeIfPresent([Swift.String].self, forKey: .member)
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
    fun `SimpleScalarPropertiesOutputResponseBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-scalar.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/RestXml/models/SimpleScalarPropertiesOutputResponseBody+Decodable.swift")
        val expectedContents = """
        struct SimpleScalarPropertiesOutputResponseBody: Swift.Equatable {
            let stringValue: Swift.String?
            let trueBooleanValue: Swift.Bool?
            let falseBooleanValue: Swift.Bool?
            let byteValue: Swift.Int8?
            let shortValue: Swift.Int16?
            let integerValue: Swift.Int?
            let longValue: Swift.Int?
            let floatValue: Swift.Float?
            let `protocol`: Swift.String?
            let doubleValue: Swift.Double?
        }
        
        extension SimpleScalarPropertiesOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case byteValue
                case doubleValue = "DoubleDribble"
                case falseBooleanValue
                case floatValue
                case integerValue
                case longValue
                case `protocol` = "protocol"
                case shortValue
                case stringValue
                case trueBooleanValue
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                let stringValueDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .stringValue)
                stringValue = stringValueDecoded
                let trueBooleanValueDecoded = try containerValues.decodeIfPresent(Swift.Bool.self, forKey: .trueBooleanValue)
                trueBooleanValue = trueBooleanValueDecoded
                let falseBooleanValueDecoded = try containerValues.decodeIfPresent(Swift.Bool.self, forKey: .falseBooleanValue)
                falseBooleanValue = falseBooleanValueDecoded
                let byteValueDecoded = try containerValues.decodeIfPresent(Swift.Int8.self, forKey: .byteValue)
                byteValue = byteValueDecoded
                let shortValueDecoded = try containerValues.decodeIfPresent(Swift.Int16.self, forKey: .shortValue)
                shortValue = shortValueDecoded
                let integerValueDecoded = try containerValues.decodeIfPresent(Swift.Int.self, forKey: .integerValue)
                integerValue = integerValueDecoded
                let longValueDecoded = try containerValues.decodeIfPresent(Swift.Int.self, forKey: .longValue)
                longValue = longValueDecoded
                let floatValueDecoded = try containerValues.decodeIfPresent(Swift.Float.self, forKey: .floatValue)
                floatValue = floatValueDecoded
                let protocolDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .protocol)
                `protocol` = protocolDecoded
                let doubleValueDecoded = try containerValues.decodeIfPresent(Swift.Double.self, forKey: .doubleValue)
                doubleValue = doubleValueDecoded
            }
        }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `nestednested wrapped list deserialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedWrappedListOutputResponseBody+Decodable.swift")
        val expectedContents = """
        extension XmlNestedNestedWrappedListOutputResponseBody: Swift.Decodable {
            enum CodingKeys: Swift.String, Swift.CodingKey {
                case nestedNestedStringList
            }
        
            public init (from decoder: Swift.Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                if containerValues.contains(.nestedNestedStringList) {
                    struct KeyVal0{struct member{}}
                    let nestedNestedStringListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .nestedNestedStringList)
                    if let nestedNestedStringListWrappedContainer = nestedNestedStringListWrappedContainer {
                        let nestedNestedStringListContainer = try nestedNestedStringListWrappedContainer.decodeIfPresent([[[Swift.String]]].self, forKey: .member)
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
    fun `empty lists decode`() {
        val context = setupTests("Isolated/Restxml/xml-lists-empty.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyListsOutputResponseBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlEmptyListsOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case booleanList
                    case integerList
                    case stringList
                    case stringSet
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    if containerValues.contains(.stringList) {
                        struct KeyVal0{struct member{}}
                        let stringListWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .stringList)
                        if let stringListWrappedContainer = stringListWrappedContainer {
                            let stringListContainer = try stringListWrappedContainer.decodeIfPresent([Swift.String].self, forKey: .member)
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
                        struct KeyVal0{struct member{}}
                        let stringSetWrappedContainer = containerValues.nestedContainerNonThrowable(keyedBy: CollectionMemberCodingKey<KeyVal0.member>.CodingKeys.self, forKey: .stringSet)
                        if let stringSetWrappedContainer = stringSetWrappedContainer {
                            let stringSetContainer = try stringSetWrappedContainer.decodeIfPresent([Swift.String].self, forKey: .member)
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

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateDeserializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
