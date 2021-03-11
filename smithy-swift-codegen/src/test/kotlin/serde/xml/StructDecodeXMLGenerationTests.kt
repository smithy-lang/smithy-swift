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
                    let myGroceryListContainer = try containerValues.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .myGroceryList)
                    let myGroceryListItemContainer = try myGroceryListContainer.decodeIfPresent([String].self, forKey: .member)
                    var myGroceryListDecoded0:[String]? = nil
                    if let myGroceryListItemContainer = myGroceryListItemContainer {
                        myGroceryListDecoded0 = [String]()
                        for string0 in myGroceryListItemContainer {
                            myGroceryListDecoded0?.append(string0)
                        }
                    }
                    myGroceryList = myGroceryListDecoded0
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
                    let myGroceryListItemContainer = try containerValues.decodeIfPresent([String].self, forKey: .myGroceryList)
                    var myGroceryListDecoded0:[String]? = nil
                    if let myGroceryListItemContainer = myGroceryListItemContainer {
                        myGroceryListDecoded0 = [String]()
                        for string0 in myGroceryListItemContainer {
                            myGroceryListDecoded0?.append(string0)
                        }
                    }
                    myGroceryList = myGroceryListDecoded0
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
