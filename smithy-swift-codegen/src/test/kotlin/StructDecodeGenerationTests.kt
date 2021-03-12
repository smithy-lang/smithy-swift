/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.AddOperationShapes
import software.amazon.smithy.swift.codegen.RecursiveShapeBoxer

class StructDecodeGenerationTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        model = RecursiveShapeBoxer.transform(model)
        return model.newTestContext()
    }
    val newTestContext = newTestContext()

    init {
        newTestContext.generator.generateDeserializers(newTestContext.generationCtx)
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates decodable conformance in correct file`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/SmokeTestOutputBody+Decodable.swift"))
    }

    @Test
    fun `it creates decodable conformance for nested structures`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested+Codable.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested2+Codable.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested3+Codable.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested4+Codable.swift"))
    }

    @Test
    fun `it creates smoke test request decodable conformance`() {
        val contents = getModelFileContents("example", "SmokeTestOutputBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct SmokeTestOutputBody: Equatable {
                public let payload1: String?
                public let payload2: Int?
                public let payload3: Nested?
            }

            extension SmokeTestOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case payload1
                    case payload2
                    case payload3
                }

                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let payload1Decoded = try containerValues.decodeIfPresent(String.self, forKey: .payload1)
                    payload1 = payload1Decoded
                    let payload2Decoded = try containerValues.decodeIfPresent(Int.self, forKey: .payload2)
                    payload2 = payload2Decoded
                    let payload3Decoded = try containerValues.decodeIfPresent(Nested.self, forKey: .payload3)
                    payload3 = payload3Decoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it decodes nested documents with aggregate shapes`() {
        val contents = getModelFileContents("example", "Nested4+Codable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension Nested4: Codable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case intList
                    case intMap
                    case member1
                    case stringMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let intList = intList {
                        var intListContainer = container.nestedUnkeyedContainer(forKey: .intList)
                        for intlist0 in intList {
                            try intListContainer.encode(intlist0)
                        }
                    }
                    if let intMap = intMap {
                        var intMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: .intMap)
                        for (dictKey0, intmap0) in intMap {
                            try intMapContainer.encode(intmap0, forKey: Key(stringValue: dictKey0))
                        }
                    }
                    if let member1 = member1 {
                        try container.encode(member1, forKey: .member1)
                    }
                    if let stringMap = stringMap {
                        var stringMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: .stringMap)
                        for (dictKey0, nestedstringmap0) in stringMap {
                            try stringMapContainer.encode(nestedstringmap0, forKey: Key(stringValue: dictKey0))
                        }
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let member1Decoded = try containerValues.decodeIfPresent(Int.self, forKey: .member1)
                    member1 = member1Decoded
                    let intListContainer = try containerValues.decodeIfPresent([Int].self, forKey: .intList)
                    var intListDecoded0:[Int]? = nil
                    if let intListContainer = intListContainer {
                        intListDecoded0 = [Int]()
                        for integer0 in intListContainer {
                            intListDecoded0?.append(integer0)
                        }
                    }
                    intList = intListDecoded0
                    let intMapContainer = try containerValues.decodeIfPresent([String:Int].self, forKey: .intMap)
                    var intMapDecoded0: [String:Int]? = nil
                    if let intMapContainer = intMapContainer {
                        intMapDecoded0 = [String:Int]()
                        for (key0, integer0) in intMapContainer {
                            intMapDecoded0?[key0] = integer0
                        }
                    }
                    intMap = intMapDecoded0
                    let stringMapContainer = try containerValues.decodeIfPresent([String:[String]?].self, forKey: .stringMap)
                    var stringMapDecoded0: [String:[String]?]? = nil
                    if let stringMapContainer = stringMapContainer {
                        stringMapDecoded0 = [String:[String]?]()
                        for (key0, stringlist0) in stringMapContainer {
                            var stringlist0Decoded0 = [String]()
                            if let stringlist0 = stringlist0 {
                                for string1 in stringlist0 {
                                    stringlist0Decoded0.append(string1)
                                }
                            }
                            stringMapDecoded0?[key0] = stringlist0Decoded0
                        }
                    }
                    stringMap = stringMapDecoded0
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it provides decodable conformance to operation outputs with timestamps`() {
        val contents =
            getModelFileContents("example", "TimestampInputOutputBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
struct TimestampInputOutputBody: Equatable {
    public let normal: Date?
    public let dateTime: Date?
    public let epochSeconds: Date?
    public let httpDate: Date?
    public let nestedTimestampList: [[Date]?]?
    public let timestampList: [Date]?
}

extension TimestampInputOutputBody: Decodable {
    private enum CodingKeys: String, CodingKey {
        case dateTime
        case epochSeconds
        case httpDate
        case nestedTimestampList
        case normal
        case timestampList
    }

    public init (from decoder: Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let normalDateString = try containerValues.decodeIfPresent(String.self, forKey: .normal)
        var normalDecoded: Date? = nil
        if let normalDateString = normalDateString {
            let normalFormatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
            normalDecoded = normalFormatter.date(from: normalDateString)
        }
        normal = normalDecoded
        let dateTimeDateString = try containerValues.decodeIfPresent(String.self, forKey: .dateTime)
        var dateTimeDecoded: Date? = nil
        if let dateTimeDateString = dateTimeDateString {
            let dateTimeFormatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
            dateTimeDecoded = dateTimeFormatter.date(from: dateTimeDateString)
        }
        dateTime = dateTimeDecoded
        let epochSecondsDecoded = try containerValues.decodeIfPresent(Date.self, forKey: .epochSeconds)
        epochSeconds = epochSecondsDecoded
        let httpDateDateString = try containerValues.decodeIfPresent(String.self, forKey: .httpDate)
        var httpDateDecoded: Date? = nil
        if let httpDateDateString = httpDateDateString {
            let httpDateFormatter = DateFormatter.rfc5322DateFormatter
            httpDateDecoded = httpDateFormatter.date(from: httpDateDateString)
        }
        httpDate = httpDateDecoded
        let nestedTimestampListContainer = try containerValues.decodeIfPresent([[String]?].self, forKey: .nestedTimestampList)
        var nestedTimestampListDecoded0:[[Date]?]? = nil
        if let nestedTimestampListContainer = nestedTimestampListContainer {
            nestedTimestampListDecoded0 = [[Date]?]()
            for list0 in nestedTimestampListContainer {
                var list0Decoded0 = [Date]()
                if let list0 = list0 {
                    for timestamp1 in list0 {
                        let timestamp1Formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                        guard let date1 = timestamp1Formatter.date(from: timestamp1) else {
                            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: containerValues.codingPath + [CodingKeys.nestedTimestampList], debugDescription: "date cannot be properly deserialized"))
                        }
                        list0Decoded0.append(date1)
                    }
                }
                nestedTimestampListDecoded0?.append(list0Decoded0)
            }
        }
        nestedTimestampList = nestedTimestampListDecoded0
        let timestampListContainer = try containerValues.decodeIfPresent([String].self, forKey: .timestampList)
        var timestampListDecoded0:[Date]? = nil
        if let timestampListContainer = timestampListContainer {
            timestampListDecoded0 = [Date]()
            for timestamp0 in timestampListContainer {
                let timestamp0Formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                guard let date0 = timestamp0Formatter.date(from: timestamp0) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: containerValues.codingPath + [CodingKeys.timestampList], debugDescription: "date cannot be properly deserialized"))
                }
                timestampListDecoded0?.append(date0)
            }
        }
        timestampList = timestampListDecoded0
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it decodes maps correctly`() {
        val contents = getModelFileContents("example", "MapInputOutputBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
struct MapInputOutputBody: Equatable {
    public let intMap: [String:Int]?
    public let structMap: [String:ReachableOnlyThroughMap]?
    public let enumMap: [String:MyEnum]?
    public let blobMap: [String:Data]?
    public let nestedMap: [String:[String:Int]?]?
    public let dateMap: [String:Date]?
}

extension MapInputOutputBody: Decodable {
    private enum CodingKeys: String, CodingKey {
        case blobMap
        case dateMap
        case enumMap
        case intMap
        case nestedMap
        case structMap
    }

    public init (from decoder: Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let intMapContainer = try containerValues.decodeIfPresent([String:Int].self, forKey: .intMap)
        var intMapDecoded0: [String:Int]? = nil
        if let intMapContainer = intMapContainer {
            intMapDecoded0 = [String:Int]()
            for (key0, integer0) in intMapContainer {
                intMapDecoded0?[key0] = integer0
            }
        }
        intMap = intMapDecoded0
        let structMapContainer = try containerValues.decodeIfPresent([String:ReachableOnlyThroughMap].self, forKey: .structMap)
        var structMapDecoded0: [String:ReachableOnlyThroughMap]? = nil
        if let structMapContainer = structMapContainer {
            structMapDecoded0 = [String:ReachableOnlyThroughMap]()
            for (key0, reachableonlythroughmap0) in structMapContainer {
                structMapDecoded0?[key0] = reachableonlythroughmap0
            }
        }
        structMap = structMapDecoded0
        let enumMapContainer = try containerValues.decodeIfPresent([String:MyEnum].self, forKey: .enumMap)
        var enumMapDecoded0: [String:MyEnum]? = nil
        if let enumMapContainer = enumMapContainer {
            enumMapDecoded0 = [String:MyEnum]()
            for (key0, myenum0) in enumMapContainer {
                enumMapDecoded0?[key0] = myenum0
            }
        }
        enumMap = enumMapDecoded0
        let blobMapContainer = try containerValues.decodeIfPresent([String:Data].self, forKey: .blobMap)
        var blobMapDecoded0: [String:Data]? = nil
        if let blobMapContainer = blobMapContainer {
            blobMapDecoded0 = [String:Data]()
            for (key0, blob0) in blobMapContainer {
                blobMapDecoded0?[key0] = blob0
            }
        }
        blobMap = blobMapDecoded0
        let nestedMapContainer = try containerValues.decodeIfPresent([String:[String:Int]?].self, forKey: .nestedMap)
        var nestedMapDecoded0: [String:[String:Int]?]? = nil
        if let nestedMapContainer = nestedMapContainer {
            nestedMapDecoded0 = [String:[String:Int]?]()
            for (key0, intmap0) in nestedMapContainer {
                var intmap0Decoded0 = [String:Int]()
                if let intmap0 = intmap0 {
                    for (key1, integer1) in intmap0 {
                        intmap0Decoded0[key1] = integer1
                    }
                }
                nestedMapDecoded0?[key0] = intmap0Decoded0
            }
        }
        nestedMap = nestedMapDecoded0
        let dateMapContainer = try containerValues.decodeIfPresent([String:String].self, forKey: .dateMap)
        var dateMapDecoded0: [String:Date]? = nil
        if let dateMapContainer = dateMapContainer {
            dateMapDecoded0 = [String:Date]()
            for (key0, timestamp0) in dateMapContainer {
                let dateMapContainerFormatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                guard let date0 = dateMapContainerFormatter.date(from: timestamp0) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: containerValues.codingPath + [CodingKeys.dateMap], debugDescription: "date cannot be properly deserialized"))
                }
                dateMapDecoded0?[key0] = date0
            }
        }
        dateMap = dateMapDecoded0
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it decodes nested diverse shapes correctly`() {
        val contents =
            getModelFileContents("example", "NestedShapesOutputBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
struct NestedShapesOutputBody: Equatable {
    public let nestedListInDict: [String:[Date]?]?
    public let nestedDictInList: [[String:String]?]?
}

extension NestedShapesOutputBody: Decodable {
    private enum CodingKeys: String, CodingKey {
        case nestedDictInList
        case nestedListInDict
    }

    public init (from decoder: Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let nestedListInDictContainer = try containerValues.decodeIfPresent([String:[String]?].self, forKey: .nestedListInDict)
        var nestedListInDictDecoded0: [String:[Date]?]? = nil
        if let nestedListInDictContainer = nestedListInDictContainer {
            nestedListInDictDecoded0 = [String:[Date]?]()
            for (key0, timestamplist0) in nestedListInDictContainer {
                var timestamplist0Decoded0 = [Date]()
                if let timestamplist0 = timestamplist0 {
                    for timestamp1 in timestamplist0 {
                        let timestamp1Formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                        guard let date1 = timestamp1Formatter.date(from: timestamp1) else {
                            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: containerValues.codingPath + [CodingKeys.nestedListInDict], debugDescription: "date cannot be properly deserialized"))
                        }
                        timestamplist0Decoded0.append(date1)
                    }
                }
                nestedListInDictDecoded0?[key0] = timestamplist0Decoded0
            }
        }
        nestedListInDict = nestedListInDictDecoded0
        let nestedDictInListContainer = try containerValues.decodeIfPresent([[String:String]?].self, forKey: .nestedDictInList)
        var nestedDictInListDecoded0:[[String:String]?]? = nil
        if let nestedDictInListContainer = nestedDictInListContainer {
            nestedDictInListDecoded0 = [[String:String]?]()
            for map0 in nestedDictInListContainer {
                var nestedDictInListContainerDecoded0 = [String:String]()
                if let map0 = map0 {
                    for (key1, string1) in map0 {
                        nestedDictInListContainerDecoded0[key1] = string1
                    }
                }
                nestedDictInListDecoded0?.append(nestedDictInListContainerDecoded0)
            }
        }
        nestedDictInList = nestedDictInListDecoded0
    }
}
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it decodes recursive boxed types correctly`() {
        val contents = getModelFileContents(
            "example",
            "RecursiveShapesInputOutputNested1+Codable.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension RecursiveShapesInputOutputNested1: Codable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case foo
                    case nested
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let foo = foo {
                        try container.encode(foo, forKey: .foo)
                    }
                    if let nested = nested {
                        try container.encode(nested.value, forKey: .nested)
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let fooDecoded = try containerValues.decodeIfPresent(String.self, forKey: .foo)
                    foo = fooDecoded
                    let nestedDecoded = try containerValues.decodeIfPresent(Box<RecursiveShapesInputOutputNested2>.self, forKey: .nested)
                    nested = nestedDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes one side of the recursive shape`() {
        val contents = getModelFileContents(
            "example",
            "RecursiveShapesInputOutputNested2+Codable.swift",
            newTestContext.manifest
        )
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension RecursiveShapesInputOutputNested2: Codable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case bar
                    case recursiveMember
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let bar = bar {
                        try container.encode(bar, forKey: .bar)
                    }
                    if let recursiveMember = recursiveMember {
                        try container.encode(recursiveMember, forKey: .recursiveMember)
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let barDecoded = try containerValues.decodeIfPresent(String.self, forKey: .bar)
                    bar = barDecoded
                    let recursiveMemberDecoded = try containerValues.decodeIfPresent(RecursiveShapesInputOutputNested1.self, forKey: .recursiveMember)
                    recursiveMember = recursiveMemberDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
