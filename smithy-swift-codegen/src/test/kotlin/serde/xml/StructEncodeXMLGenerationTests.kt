package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class StructEncodeXMLGenerationTests {
    @Test
    fun `wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-wrapped-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlWrappedListInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case myGroceryList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let myGroceryList = myGroceryList {
                        var myGroceryListContainer = container.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .myGroceryList)
                        for grocerylist0 in myGroceryList {
                            try myGroceryListContainer.encode(grocerylist0, forKey: .member)
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-flattened-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedListInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case myGroceryList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let myGroceryList = myGroceryList {
                        var myGroceryListContainer = container.nestedUnkeyedContainer(forKey: .myGroceryList)
                        for grocerylist0 in myGroceryList {
                            try myGroceryListContainer.encode(grocerylist0)
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `simpleScalar serialization`() {
        val context = setupTests("Isolated/Restxml/xml-scalar.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/SimpleScalarPropertiesInput+Encodable.swift")
        val expectedContents =
            """
            extension SimpleScalarPropertiesInput: Encodable, Reflection {
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
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let byteValue = byteValue {
                        try container.encode(byteValue, forKey: .byteValue)
                    }
                    if let doubleValue = doubleValue {
                        try container.encode(doubleValue, forKey: .doubleValue)
                    }
                    if let falseBooleanValue = falseBooleanValue {
                        try container.encode(falseBooleanValue, forKey: .falseBooleanValue)
                    }
                    if let floatValue = floatValue {
                        try container.encode(floatValue, forKey: .floatValue)
                    }
                    if let integerValue = integerValue {
                        try container.encode(integerValue, forKey: .integerValue)
                    }
                    if let longValue = longValue {
                        try container.encode(longValue, forKey: .longValue)
                    }
                    if let shortValue = shortValue {
                        try container.encode(shortValue, forKey: .shortValue)
                    }
                    if let stringValue = stringValue {
                        try container.encode(stringValue, forKey: .stringValue)
                    }
                    if let trueBooleanValue = trueBooleanValue {
                        try container.encode(trueBooleanValue, forKey: .trueBooleanValue)
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
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
