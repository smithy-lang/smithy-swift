package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class StructDecodeXMLGenerationTests {
    @Test
    fun `XmlWrappedListOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-wrapped-list.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/example/models/XmlWrappedListOutputBody+Decodable.swift")
        val expectedContents = """
            extension XmlWrappedListOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case myGroceryList
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let myGroceryListWrappedContainer = try containerValues.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .myGroceryList)
                    let myGroceryListContainer = try myGroceryListWrappedContainer.decodeIfPresent([String].self, forKey: .member)
                    var myGroceryListBuffer:[String]? = nil
                    if let myGroceryListContainer = myGroceryListContainer {
                        myGroceryListBuffer = [String]()
                        for stringContainer0 in myGroceryListContainer {
                            myGroceryListBuffer?.append(stringContainer0)
                        }
                    }
                    myGroceryList = myGroceryListBuffer
                }
            }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `XmlFlattenedListOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-flattened-list.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/example/models/XmlFlattenedListOutputBody+Decodable.swift")
        val expectedContents = """
            extension XmlFlattenedListOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case myGroceryList
                }

                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let myGroceryListContainer = try containerValues.decodeIfPresent([String].self, forKey: .myGroceryList)
                    var myGroceryListBuffer:[String]? = nil
                    if let myGroceryListContainer = myGroceryListContainer {
                        myGroceryListBuffer = [String]()
                        for stringContainer0 in myGroceryListContainer {
                            myGroceryListBuffer?.append(stringContainer0)
                        }
                    }
                    myGroceryList = myGroceryListBuffer
                }
            }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `SimpleScalarPropertiesOutputBody decodable`() {
        val context = setupTests("Isolated/Restxml/xml-scalar.smithy", "aws.protocoltests.restxml#RestXml")

        val contents = getFileContents(context.manifest, "/example/models/SimpleScalarPropertiesOutputBody+Decodable.swift")
        val expectedContents = """
        extension SimpleScalarPropertiesOutputBody: Decodable {
            private enum CodingKeys: String, CodingKey {
                case byteValue
                case doubleValue
                case falseBooleanValue
                case floatValue
                case integerValue
                case longValue
                case shortValue
                case stringValue
                case trueBooleanValue
            }
        
            public init (from decoder: Decoder) throws {
                let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                let stringValueDecoded = try containerValues.decodeIfPresent(String.self, forKey: .stringValue)
                stringValue = stringValueDecoded
                let trueBooleanValueDecoded = try containerValues.decodeIfPresent(Bool.self, forKey: .trueBooleanValue)
                trueBooleanValue = trueBooleanValueDecoded
                let falseBooleanValueDecoded = try containerValues.decodeIfPresent(Bool.self, forKey: .falseBooleanValue)
                falseBooleanValue = falseBooleanValueDecoded
                let byteValueDecoded = try containerValues.decodeIfPresent(Int8.self, forKey: .byteValue)
                byteValue = byteValueDecoded
                let shortValueDecoded = try containerValues.decodeIfPresent(Int16.self, forKey: .shortValue)
                shortValue = shortValueDecoded
                let integerValueDecoded = try containerValues.decodeIfPresent(Int.self, forKey: .integerValue)
                integerValue = integerValueDecoded
                let longValueDecoded = try containerValues.decodeIfPresent(Int.self, forKey: .longValue)
                longValue = longValueDecoded
                let floatValueDecoded = try containerValues.decodeIfPresent(Float.self, forKey: .floatValue)
                floatValue = floatValueDecoded
                let doubleValueDecoded = try containerValues.decodeIfPresent(Double.self, forKey: .doubleValue)
                doubleValue = doubleValueDecoded
            }
        }
        """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `nestednested wrapped list deserialization`() {
        val context = setupTests("Isolated/Restxml/xml-nestednested-wrapped-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedNestedWrappedListOutputBody+Decodable.swift")
        val expectedContents = """
            extension XmlNestedNestedWrappedListOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let nestedNestedStringListWrappedContainer = try containerValues.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .nestedNestedStringList)
                    let nestedNestedStringListContainer = try nestedNestedStringListWrappedContainer.decodeIfPresent([[[String]?]?].self, forKey: .member)
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
                }
            }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `nestednested flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-nestednested-Flattened-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedNestedFlattenedListOutputBody+Decodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedFlattenedListOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
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
