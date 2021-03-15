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
                        for string0 in myGroceryList {
                            try myGroceryListContainer.encode(string0, forKey: .member)
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
                        for string0 in myGroceryList {
                            try myGroceryListContainer.encode(string0)
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
    @Test
    fun `nested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-nested-wrapped-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedWrappedListInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case nestedStringList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedStringList = nestedStringList {
                        var nestedStringListContainer = container.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .nestedStringList)
                        for stringlist0 in nestedStringList {
                            if let stringlist0 = stringlist0 {
                                var stringlist0Container0 = nestedStringListContainer.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .member)
                                for string1 in stringlist0 {
                                    try stringlist0Container0.encode(string1, forKey: .member)
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
    fun `nestednested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-nestednested-wrapped-list.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedWrappedListInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedNestedStringList = nestedNestedStringList {
                        var nestedNestedStringListContainer = container.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .nestedNestedStringList)
                        for nestedstringlist0 in nestedNestedStringList {
                            if let nestedstringlist0 = nestedstringlist0 {
                                var nestedstringlist0Container0 = nestedNestedStringListContainer.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .member)
                                for stringlist1 in nestedstringlist0 {
                                    if let stringlist1 = stringlist1 {
                                        var stringlist1Container1 = nestedstringlist0Container0.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .member)
                                        for string2 in stringlist1 {
                                            try stringlist1Container1.encode(string2, forKey: .member)
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
    fun `nestednested flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-nestednested-Flattened-list.smithy", "aws.protocoltests.restxml#RestXml")
        print(getFileContents(context.manifest, "/example/models/XmlNestedNestedFlattenedListInput.swift"))
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedNestedFlattenedListInput+Encodable.swift")
        print(contents)
        val expectedContents =
            """
            extension XmlNestedNestedFlattenedListInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedNestedStringList = nestedNestedStringList {
                        var nestedNestedStringListContainer = container.nestedUnkeyedContainer(forKey: .nestedNestedStringList)
                        for nestedstringlist0 in nestedNestedStringList {
                            if let nestedstringlist0 = nestedstringlist0 {
                                var nestedstringlist0ContainerForUnkeyed0 = nestedNestedStringListContainer.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self)
                                var nestedstringlist0Container0 = nestedstringlist0ContainerForUnkeyed0.nestedUnkeyedContainer(forKey: .member)
                                for stringlist1 in nestedstringlist0 {
                                    if let stringlist1 = stringlist1 {
                                        var stringlist1ContainerForUnkeyed1 = nestedstringlist0Container0.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self)
                                        var stringlist1Container1 = stringlist1ContainerForUnkeyed1.nestedUnkeyedContainer(forKey: .member)
                                        for string2 in stringlist1 {
                                            try stringlist1Container1.encode(string2)
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

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestXMLProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "RestXml", "2019-12-16", "Rest Xml Protocol")
        }
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
