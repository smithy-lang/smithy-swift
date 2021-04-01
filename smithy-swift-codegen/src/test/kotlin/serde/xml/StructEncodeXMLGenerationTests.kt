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
        val context = setupTests("Isolated/Restxml/xml-lists-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlWrappedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myGroceryList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let myGroceryList = myGroceryList {
                        var myGroceryListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .myGroceryList)
                        for string0 in myGroceryList {
                            try myGroceryListContainer.encode(string0, forKey: Key("member"))
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
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
                enum CodingKeys: String, CodingKey {
                    case byteValue
                    case doubleValue = "DoubleDribble"
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
        val context = setupTests("Isolated/Restxml/xml-lists-nested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedWrappedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedStringList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedStringList = nestedStringList {
                        var nestedStringListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .nestedStringList)
                        for stringlist0 in nestedStringList {
                            if let stringlist0 = stringlist0 {
                                var stringlist0Container0 = nestedStringListContainer.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                for string1 in stringlist0 {
                                    try stringlist0Container0.encode(string1, forKey: Key("member"))
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
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedWrappedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedNestedStringList = nestedNestedStringList {
                        var nestedNestedStringListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .nestedNestedStringList)
                        for nestedstringlist0 in nestedNestedStringList {
                            if let nestedstringlist0 = nestedstringlist0 {
                                var nestedstringlist0Container0 = nestedNestedStringListContainer.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                for stringlist1 in nestedstringlist0 {
                                    if let stringlist1 = stringlist1 {
                                        var stringlist1Container1 = nestedstringlist0Container0.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                        for string2 in stringlist1 {
                                            try stringlist1Container1.encode(string2, forKey: Key("member"))
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
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedNestedFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedFlattenedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedNestedStringList = nestedNestedStringList {
                        var nestedNestedStringListContainer = container.nestedUnkeyedContainer(forKey: .nestedNestedStringList)
                        for nestedstringlist0 in nestedNestedStringList {
                            if let nestedstringlist0 = nestedstringlist0 {
                                var nestedstringlist0ContainerForUnkeyed0 = nestedNestedStringListContainer.nestedContainer(keyedBy: Key.self)
                                var nestedstringlist0Container0 = nestedstringlist0ContainerForUnkeyed0.nestedUnkeyedContainer(forKey: Key("member"))
                                for stringlist1 in nestedstringlist0 {
                                    if let stringlist1 = stringlist1 {
                                        var stringlist1ContainerForUnkeyed1 = nestedstringlist0Container0.nestedContainer(keyedBy: Key.self)
                                        var stringlist1Container1 = stringlist1ContainerForUnkeyed1.nestedUnkeyedContainer(forKey: Key("member"))
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

    @Test
    fun `empty lists`() {
        val context = setupTests("Isolated/Restxml/xml-lists-empty.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlEmptyListsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEmptyListsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case booleanList
                    case integerList
                    case stringList
                    case stringSet
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let booleanList = booleanList {
                        var booleanListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .booleanList)
                        for primitiveboolean0 in booleanList {
                            try booleanListContainer.encode(primitiveboolean0, forKey: Key("member"))
                        }
                    }
                    if let integerList = integerList {
                        var integerListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .integerList)
                        for integer0 in integerList {
                            try integerListContainer.encode(integer0, forKey: Key("member"))
                        }
                    }
                    if let stringList = stringList {
                        var stringListContainer = container.nestedContainer(keyedBy: Key.self, forKey: .stringList)
                        for string0 in stringList {
                            try stringListContainer.encode(string0, forKey: Key("member"))
                        }
                    }
                    if let stringSet = stringSet {
                        var stringSetContainer = container.nestedContainer(keyedBy: Key.self, forKey: .stringSet)
                        for string0 in stringSet {
                            try stringSetContainer.encode(string0, forKey: Key("member"))
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
