package serde.xml

import MockHttpRestXMLProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ListEncodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlListXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let renamedListMembers = renamedListMembers {
                        var renamedListMembersContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("renamed"))
                        for string0 in renamedListMembers {
                            try renamedListMembersContainer.encode(string0, forKey: Key("item"))
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 nested wrapped list with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname-nested.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlListXmlNameNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameNestedInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let renamedListMembers = renamedListMembers {
                        var renamedListMembersContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("renamed"))
                        for renamedlistmembers0 in renamedListMembers {
                            if let renamedlistmembers0 = renamedlistmembers0 {
                                var renamedlistmembers0Container0 = renamedListMembersContainer.nestedContainer(keyedBy: Key.self, forKey: Key("item"))
                                for string1 in renamedlistmembers0 {
                                    try renamedlistmembers0Container0.encode(string1, forKey: Key("subItem"))
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
    fun `003 nested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedWrappedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedStringList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let nestedStringList = nestedStringList {
                        var nestedStringListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("nestedStringList"))
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
    fun `004 nestednested wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedWrappedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let nestedNestedStringList = nestedNestedStringList {
                        var nestedNestedStringListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("nestedNestedStringList"))
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
    fun `005 nestednested flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-nestednested-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlNestedNestedFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedFlattenedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let nestedNestedStringList = nestedNestedStringList {
                        if nestedNestedStringList.isEmpty {
                            var nestedNestedStringListContainer = container.nestedUnkeyedContainer(forKey: Key("nestedNestedStringList"))
                            try nestedNestedStringListContainer.encodeNil()
                        } else {
                            for nestedstringlist0 in nestedNestedStringList {
                                if let nestedstringlist0 = nestedstringlist0 {
                                    var nestedstringlist0Container0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("nestedNestedStringList"))
                                    for stringlist1 in nestedstringlist0 {
                                        if let stringlist1 = stringlist1 {
                                            var stringlist1Container1 = nestedstringlist0Container0.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                            for string2 in stringlist1 {
                                                var stringlist1Container2 = stringlist1Container1.nestedContainer(keyedBy: Key.self, forKey: Key("member"))
                                                try stringlist1Container2.encode(string2, forKey: Key(""))
                                            }
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
    fun `006 empty lists`() {
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
                    var container = encoder.container(keyedBy: Key.self)
                    if let booleanList = booleanList {
                        var booleanListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("booleanList"))
                        for primitiveboolean0 in booleanList {
                            try booleanListContainer.encode(primitiveboolean0, forKey: Key("member"))
                        }
                    }
                    if let integerList = integerList {
                        var integerListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("integerList"))
                        for integer0 in integerList {
                            try integerListContainer.encode(integer0, forKey: Key("member"))
                        }
                    }
                    if let stringList = stringList {
                        var stringListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("stringList"))
                        for string0 in stringList {
                            try stringListContainer.encode(string0, forKey: Key("member"))
                        }
                    }
                    if let stringSet = stringSet {
                        var stringSetContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("stringSet"))
                        for string0 in stringSet {
                            try stringSetContainer.encode(string0, forKey: Key("member"))
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 wrapped list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-wrapped.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlWrappedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myGroceryList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myGroceryList = myGroceryList {
                        var myGroceryListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("myGroceryList"))
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
    fun `008 flattened list serialization`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedListInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case myGroceryList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let myGroceryList = myGroceryList {
                        if myGroceryList.isEmpty {
                            var myGroceryListContainer = container.nestedUnkeyedContainer(forKey: Key("myGroceryList"))
                            try myGroceryListContainer.encodeNil()
                        } else {
                            for string0 in myGroceryList {
                                var myGroceryListContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("myGroceryList"))
                                try myGroceryListContainer0.encode(string0, forKey: Key(""))
                            }
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `009 encode nested flattened date time with namespace`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-nested-datetime.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsNestedFlattenedInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedFlattenedInput: DynamicNodeEncoding {
                public static func nodeEncoding(for key: CodingKey) -> NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns:baz"
                    ]
                    if let key = key as? Key {
                        if xmlNamespaceValues.contains(key.stringValue) {
                            return .attribute
                        }
                    }
                    return .element
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `010 encode nested flattened datetime encodable`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-nested-datetime.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlTimestampsNestedFlattenedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedFlattenedInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedTimestampList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let nestedTimestampList = nestedTimestampList {
                        if nestedTimestampList.isEmpty {
                            var nestedTimestampListContainer = container.nestedUnkeyedContainer(forKey: Key("nestedTimestampList"))
                            try nestedTimestampListContainer.encodeNil()
                        } else {
                            for nestedtimestamplist0 in nestedTimestampList {
                                if let nestedtimestamplist0 = nestedtimestamplist0 {
                                    var nestedtimestamplist0Container0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("nestedTimestampList"))
                                    for timestamp1 in nestedtimestamplist0 {
                                        var nestedtimestamplist0Container1 = nestedtimestamplist0Container0.nestedContainer(keyedBy: Key.self, forKey: Key("nestedMember"))
                                        try nestedtimestamplist0Container1.encode("http://baz.com", forKey: Key("xmlns:baz"))
                                        try nestedtimestamplist0Container1.encode(TimestampWrapper(timestamp1, format: .epochSeconds), forKey: Key(""))
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
    fun `011 encode flattened empty list`() {
        val context = setupTests("Isolated/Restxml/xml-lists-emptyFlattened.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlEmptyFlattenedListsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEmptyFlattenedListsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case booleanList
                    case integerList
                    case stringList
                    case stringSet
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let booleanList = booleanList {
                        var booleanListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("booleanList"))
                        for primitiveboolean0 in booleanList {
                            try booleanListContainer.encode(primitiveboolean0, forKey: Key("member"))
                        }
                    }
                    if let integerList = integerList {
                        var integerListContainer = container.nestedContainer(keyedBy: Key.self, forKey: Key("integerList"))
                        for integer0 in integerList {
                            try integerListContainer.encode(integer0, forKey: Key("member"))
                        }
                    }
                    if let stringList = stringList {
                        if stringList.isEmpty {
                            var stringListContainer = container.nestedUnkeyedContainer(forKey: Key("stringList"))
                            try stringListContainer.encodeNil()
                        } else {
                            for string0 in stringList {
                                var stringListContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("stringList"))
                                try stringListContainer0.encode(string0, forKey: Key(""))
                            }
                        }
                    }
                    if let stringSet = stringSet {
                        if stringSet.isEmpty {
                            var stringSetContainer = container.nestedUnkeyedContainer(forKey: Key("stringSet"))
                            try stringSetContainer.encodeNil()
                        } else {
                            for string0 in stringSet {
                                var stringSetContainer0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("stringSet"))
                                try stringSetContainer0.encode(string0, forKey: Key(""))
                            }
                        }
                    }
                }
            }
            """.trimIndent()

        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `011 encode list flattened nested with xmlname`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-nested-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/example/models/XmlListNestedFlattenedXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListNestedFlattenedXmlNameInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case nestedList = "listOfNestedStrings"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: Key.self)
                    if let nestedList = nestedList {
                        if nestedList.isEmpty {
                            var nestedListContainer = container.nestedUnkeyedContainer(forKey: Key("listOfNestedStrings"))
                            try nestedListContainer.encodeNil()
                        } else {
                            for nestedstringmember0 in nestedList {
                                if let nestedstringmember0 = nestedstringmember0 {
                                    var nestedstringmember0Container0 = container.nestedContainer(keyedBy: Key.self, forKey: Key("listOfNestedStrings"))
                                    for string1 in nestedstringmember0 {
                                        var nestedstringmember0Container1 = nestedstringmember0Container0.nestedContainer(keyedBy: Key.self, forKey: Key("nestedMember"))
                                        try nestedstringmember0Container1.encode(string1, forKey: Key(""))
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
