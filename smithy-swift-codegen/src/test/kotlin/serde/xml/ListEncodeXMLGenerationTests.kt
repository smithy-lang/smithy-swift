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

class ListEncodeXMLGenerationTests {
    @Test
    fun `001 wrapped list with xmlName`() {
        val context = setupTests("Isolated/Restxml/xml-lists-xmlname.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let renamedListMembers = renamedListMembers {
                        var renamedListMembersContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("renamed"))
                        for string0 in renamedListMembers {
                            try renamedListMembersContainer.encode(string0, forKey: ClientRuntime.Key("item"))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListXmlNameNestedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListXmlNameNestedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case renamedListMembers = "renamed"
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let renamedListMembers = renamedListMembers {
                        var renamedListMembersContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("renamed"))
                        for renamedlistmembers0 in renamedListMembers {
                            var renamedlistmembers0Container0 = renamedListMembersContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("item"))
                            for string1 in renamedlistmembers0 {
                                try renamedlistmembers0Container0.encode(string1, forKey: ClientRuntime.Key("subItem"))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedWrappedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedStringList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let nestedStringList = nestedStringList {
                        var nestedStringListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedStringList"))
                        for stringlist0 in nestedStringList {
                            var stringlist0Container0 = nestedStringListContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                            for string1 in stringlist0 {
                                try stringlist0Container0.encode(string1, forKey: ClientRuntime.Key("member"))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedWrappedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedNestedStringList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let nestedNestedStringList = nestedNestedStringList {
                        var nestedNestedStringListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedNestedStringList"))
                        for nestedstringlist0 in nestedNestedStringList {
                            var nestedstringlist0Container0 = nestedNestedStringListContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                            for stringlist1 in nestedstringlist0 {
                                var stringlist1Container1 = nestedstringlist0Container0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                                for string2 in stringlist1 {
                                    try stringlist1Container1.encode(string2, forKey: ClientRuntime.Key("member"))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlNestedNestedFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlNestedNestedFlattenedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedNestedStringList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let nestedNestedStringList = nestedNestedStringList {
                        if nestedNestedStringList.isEmpty {
                            var nestedNestedStringListContainer = container.nestedUnkeyedContainer(forKey: ClientRuntime.Key("nestedNestedStringList"))
                            try nestedNestedStringListContainer.encodeNil()
                        } else {
                            for nestedstringlist0 in nestedNestedStringList {
                                if let nestedstringlist0 = nestedstringlist0 {
                                    var nestedstringlist0Container0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedNestedStringList"))
                                    for stringlist1 in nestedstringlist0 {
                                        if let stringlist1 = stringlist1 {
                                            var stringlist1Container1 = nestedstringlist0Container0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                                            for string2 in stringlist1 {
                                                var stringlist1Container2 = stringlist1Container1.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                                                try stringlist1Container2.encode(string2, forKey: ClientRuntime.Key(""))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyListsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEmptyListsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case booleanList
                    case integerList
                    case stringList
                    case stringSet
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let booleanList = booleanList {
                        var booleanListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("booleanList"))
                        for primitiveboolean0 in booleanList {
                            try booleanListContainer.encode(primitiveboolean0, forKey: ClientRuntime.Key("member"))
                        }
                    }
                    if let integerList = integerList {
                        var integerListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("integerList"))
                        for integer0 in integerList {
                            try integerListContainer.encode(integer0, forKey: ClientRuntime.Key("member"))
                        }
                    }
                    if let stringList = stringList {
                        var stringListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("stringList"))
                        for string0 in stringList {
                            try stringListContainer.encode(string0, forKey: ClientRuntime.Key("member"))
                        }
                    }
                    if let stringSet = stringSet {
                        var stringSetContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("stringSet"))
                        for string0 in stringSet {
                            try stringSetContainer.encode(string0, forKey: ClientRuntime.Key("member"))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlWrappedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlWrappedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myGroceryList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let myGroceryList = myGroceryList {
                        var myGroceryListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("myGroceryList"))
                        for string0 in myGroceryList {
                            try myGroceryListContainer.encode(string0, forKey: ClientRuntime.Key("member"))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlFlattenedListInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlFlattenedListInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myGroceryList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let myGroceryList = myGroceryList {
                        if myGroceryList.isEmpty {
                            var myGroceryListContainer = container.nestedUnkeyedContainer(forKey: ClientRuntime.Key("myGroceryList"))
                            try myGroceryListContainer.encodeNil()
                        } else {
                            for string0 in myGroceryList {
                                var myGroceryListContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("myGroceryList"))
                                try myGroceryListContainer0.encode(string0, forKey: ClientRuntime.Key(""))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedFlattenedInput+DynamicNodeEncoding.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedFlattenedInput: ClientRuntime.DynamicNodeEncoding {
                public static func nodeEncoding(for key: Swift.CodingKey) -> ClientRuntime.NodeEncoding {
                    let xmlNamespaceValues = [
                        "xmlns:baz"
                    ]
                    if let key = key as? ClientRuntime.Key {
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlTimestampsNestedFlattenedInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlTimestampsNestedFlattenedInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedTimestampList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let nestedTimestampList = nestedTimestampList {
                        if nestedTimestampList.isEmpty {
                            var nestedTimestampListContainer = container.nestedUnkeyedContainer(forKey: ClientRuntime.Key("nestedTimestampList"))
                            try nestedTimestampListContainer.encodeNil()
                        } else {
                            for nestedtimestamplist0 in nestedTimestampList {
                                if let nestedtimestamplist0 = nestedtimestamplist0 {
                                    var nestedtimestamplist0Container0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedTimestampList"))
                                    for timestamp1 in nestedtimestamplist0 {
                                        var nestedtimestamplist0Container1 = nestedtimestamplist0Container0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedMember"))
                                        try nestedtimestamplist0Container1.encode("http://baz.com", forKey: ClientRuntime.Key("xmlns:baz"))
                                        try nestedtimestamplist0Container1.encodeTimestamp(timestamp1, format: .epochSeconds, forKey: Key(""))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlEmptyFlattenedListsInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlEmptyFlattenedListsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case booleanList
                    case integerList
                    case stringList
                    case stringSet
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let booleanList = booleanList {
                        var booleanListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("booleanList"))
                        for primitiveboolean0 in booleanList {
                            try booleanListContainer.encode(primitiveboolean0, forKey: ClientRuntime.Key("member"))
                        }
                    }
                    if let integerList = integerList {
                        var integerListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("integerList"))
                        for integer0 in integerList {
                            try integerListContainer.encode(integer0, forKey: ClientRuntime.Key("member"))
                        }
                    }
                    if let stringList = stringList {
                        if stringList.isEmpty {
                            var stringListContainer = container.nestedUnkeyedContainer(forKey: ClientRuntime.Key("stringList"))
                            try stringListContainer.encodeNil()
                        } else {
                            for string0 in stringList {
                                var stringListContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("stringList"))
                                try stringListContainer0.encode(string0, forKey: ClientRuntime.Key(""))
                            }
                        }
                    }
                    if let stringSet = stringSet {
                        if stringSet.isEmpty {
                            var stringSetContainer = container.nestedUnkeyedContainer(forKey: ClientRuntime.Key("stringSet"))
                            try stringSetContainer.encodeNil()
                        } else {
                            for string0 in stringSet {
                                var stringSetContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("stringSet"))
                                try stringSetContainer0.encode(string0, forKey: ClientRuntime.Key(""))
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
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListNestedFlattenedXmlNameInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListNestedFlattenedXmlNameInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedList = "listOfNestedStrings"
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let nestedList = nestedList {
                        if nestedList.isEmpty {
                            var nestedListContainer = container.nestedUnkeyedContainer(forKey: ClientRuntime.Key("listOfNestedStrings"))
                            try nestedListContainer.encodeNil()
                        } else {
                            for nestedstringmember0 in nestedList {
                                if let nestedstringmember0 = nestedstringmember0 {
                                    var nestedstringmember0Container0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("listOfNestedStrings"))
                                    for string1 in nestedstringmember0 {
                                        var nestedstringmember0Container1 = nestedstringmember0Container0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("nestedMember"))
                                        try nestedstringmember0Container1.encode(string1, forKey: ClientRuntime.Key(""))
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
    fun `012 encode list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListContainMapInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListContainMapInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let myList = myList {
                        var myListContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("myList"))
                        for mysimplemap0 in myList {
                            var myListContainer0 = myListContainer.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("member"))
                            if let mysimplemap0 = mysimplemap0 {
                                for (stringKey0, stringValue0) in mysimplemap0 {
                                    var entryContainer0 = myListContainer0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("entry"))
                                    var keyContainer0 = entryContainer0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("key"))
                                    try keyContainer0.encode(stringKey0, forKey: ClientRuntime.Key(""))
                                    var valueContainer0 = entryContainer0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("value"))
                                    try valueContainer0.encode(stringValue0, forKey: ClientRuntime.Key(""))
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
    fun `013 encode flattened list containing map`() {
        val context = setupTests("Isolated/Restxml/xml-lists-flattened-contain-map.smithy", "aws.protocoltests.restxml#RestXml")
        val contents = getFileContents(context.manifest, "/RestXml/models/XmlListFlattenedContainMapInput+Encodable.swift")
        val expectedContents =
            """
            extension XmlListFlattenedContainMapInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case myList
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var container = encoder.container(keyedBy: ClientRuntime.Key.self)
                    if let myList = myList {
                        if myList.isEmpty {
                            var myListContainer = container.nestedUnkeyedContainer(forKey: ClientRuntime.Key("myList"))
                            try myListContainer.encodeNil()
                        } else {
                            for mysimplemap0 in myList {
                                var myListContainer0 = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("myList"))
                                if let mysimplemap0 = mysimplemap0 {
                                    for (stringKey0, stringValue0) in mysimplemap0 {
                                        var entryContainer0 = myListContainer0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("entry"))
                                        var keyContainer0 = entryContainer0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("key"))
                                        try keyContainer0.encode(stringKey0, forKey: ClientRuntime.Key(""))
                                        var valueContainer0 = entryContainer0.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: ClientRuntime.Key("value"))
                                        try valueContainer0.encode(stringValue0, forKey: ClientRuntime.Key(""))
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
