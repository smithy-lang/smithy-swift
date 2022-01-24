/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes
import software.amazon.smithy.swift.codegen.model.NestedShapeTransformer
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer

class StructDecodeGenerationTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        model = RecursiveShapeBoxer.transform(model)
        model = NestedShapeTransformer.transform(model, settings.getService(model))
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
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/SmokeTestOutputResponseBody+Decodable.swift"))
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
        val contents = getModelFileContents("example", "SmokeTestOutputResponseBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct SmokeTestOutputResponseBody: Swift.Equatable {
                public let payload1: Swift.String?
                public let payload2: Swift.Int?
                public let payload3: ExampleClientTypes.Nested?
            }
            
            extension SmokeTestOutputResponseBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case payload1
                    case payload2
                    case payload3
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let payload1Decoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .payload1)
                    payload1 = payload1Decoded
                    let payload2Decoded = try containerValues.decodeIfPresent(Swift.Int.self, forKey: .payload2)
                    payload2 = payload2Decoded
                    let payload3Decoded = try containerValues.decodeIfPresent(ExampleClientTypes.Nested.self, forKey: .payload3)
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
            extension ExampleClientTypes.Nested4: Swift.Codable, Runtime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case intList
                    case intMap
                    case member1
                    case stringMap
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var encodeContainer = encoder.container(keyedBy: CodingKeys.self)
                    if let intList = intList {
                        var intListContainer = encodeContainer.nestedUnkeyedContainer(forKey: .intList)
                        for intlist0 in intList {
                            try intListContainer.encode(intlist0)
                        }
                    }
                    if let intMap = intMap {
                        var intMapContainer = encodeContainer.nestedContainer(keyedBy: Runtime.Key.self, forKey: .intMap)
                        for (dictKey0, intmap0) in intMap {
                            try intMapContainer.encode(intmap0, forKey: Runtime.Key(stringValue: dictKey0))
                        }
                    }
                    if let member1 = member1 {
                        try encodeContainer.encode(member1, forKey: .member1)
                    }
                    if let stringMap = stringMap {
                        var stringMapContainer = encodeContainer.nestedContainer(keyedBy: Runtime.Key.self, forKey: .stringMap)
                        for (dictKey0, nestedstringmap0) in stringMap {
                            try stringMapContainer.encode(nestedstringmap0, forKey: Runtime.Key(stringValue: dictKey0))
                        }
                    }
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let member1Decoded = try containerValues.decodeIfPresent(Swift.Int.self, forKey: .member1)
                    member1 = member1Decoded
                    let intListContainer = try containerValues.decodeIfPresent([Swift.Int?].self, forKey: .intList)
                    var intListDecoded0:[Swift.Int]? = nil
                    if let intListContainer = intListContainer {
                        intListDecoded0 = [Swift.Int]()
                        for integer0 in intListContainer {
                            if let integer0 = integer0 {
                                intListDecoded0?.append(integer0)
                            }
                        }
                    }
                    intList = intListDecoded0
                    let intMapContainer = try containerValues.decodeIfPresent([Swift.String: Swift.Int?].self, forKey: .intMap)
                    var intMapDecoded0: [Swift.String:Swift.Int]? = nil
                    if let intMapContainer = intMapContainer {
                        intMapDecoded0 = [Swift.String:Swift.Int]()
                        for (key0, integer0) in intMapContainer {
                            if let integer0 = integer0 {
                                intMapDecoded0?[key0] = integer0
                            }
                        }
                    }
                    intMap = intMapDecoded0
                    let stringMapContainer = try containerValues.decodeIfPresent([Swift.String: [Swift.String?]?].self, forKey: .stringMap)
                    var stringMapDecoded0: [Swift.String:[Swift.String]]? = nil
                    if let stringMapContainer = stringMapContainer {
                        stringMapDecoded0 = [Swift.String:[Swift.String]]()
                        for (key0, stringlist0) in stringMapContainer {
                            var stringlist0Decoded0: [Swift.String]? = nil
                            if let stringlist0 = stringlist0 {
                                stringlist0Decoded0 = [Swift.String]()
                                for string1 in stringlist0 {
                                    if let string1 = string1 {
                                        stringlist0Decoded0?.append(string1)
                                    }
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
            getModelFileContents("example", "TimestampInputOutputResponseBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
struct TimestampInputOutputResponseBody: Swift.Equatable {
    public let normal: Runtime.Date?
    public let dateTime: Runtime.Date?
    public let epochSeconds: Runtime.Date?
    public let httpDate: Runtime.Date?
    public let nestedTimestampList: [[Runtime.Date]]?
    public let timestampList: [Runtime.Date]?
}

extension TimestampInputOutputResponseBody: Swift.Decodable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case dateTime
        case epochSeconds
        case httpDate
        case nestedTimestampList
        case normal
        case timestampList
    }

    public init (from decoder: Swift.Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let normalDateString = try containerValues.decodeIfPresent(Swift.String.self, forKey: .normal)
        var normalDecoded: Runtime.Date? = nil
        if let normalDateString = normalDateString {
            let normalFormatter = Runtime.DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
            normalDecoded = normalFormatter.date(from: normalDateString)
        }
        normal = normalDecoded
        let dateTimeDateString = try containerValues.decodeIfPresent(Swift.String.self, forKey: .dateTime)
        var dateTimeDecoded: Runtime.Date? = nil
        if let dateTimeDateString = dateTimeDateString {
            let dateTimeFormatter = Runtime.DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
            dateTimeDecoded = dateTimeFormatter.date(from: dateTimeDateString)
        }
        dateTime = dateTimeDecoded
        let epochSecondsDecoded = try containerValues.decodeIfPresent(Runtime.Date.self, forKey: .epochSeconds)
        epochSeconds = epochSecondsDecoded
        let httpDateDateString = try containerValues.decodeIfPresent(Swift.String.self, forKey: .httpDate)
        var httpDateDecoded: Runtime.Date? = nil
        if let httpDateDateString = httpDateDateString {
            let httpDateFormatter = Runtime.DateFormatter.rfc5322DateFormatter
            httpDateDecoded = httpDateFormatter.date(from: httpDateDateString)
        }
        httpDate = httpDateDecoded
        let nestedTimestampListContainer = try containerValues.decodeIfPresent([[Swift.String?]?].self, forKey: .nestedTimestampList)
        var nestedTimestampListDecoded0:[[Runtime.Date]]? = nil
        if let nestedTimestampListContainer = nestedTimestampListContainer {
            nestedTimestampListDecoded0 = [[Runtime.Date]]()
            for list0 in nestedTimestampListContainer {
                var list0Decoded0: [Swift.String]? = nil
                if let list0 = list0 {
                    list0Decoded0 = [Swift.String]()
                    for timestamp1 in list0 {
                        let timestamp1Formatter = Runtime.DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                        guard let date1 = timestamp1Formatter.date(from: timestamp1) else {
                            throw Swift.DecodingError.dataCorrupted(Swift.DecodingError.Context(codingPath: containerValues.codingPath + [CodingKeys.nestedTimestampList], debugDescription: "date cannot be properly deserialized"))
                        }
                        list0Decoded0?.append(date1)
                    }
                }
                if let list0Decoded0 = list0Decoded0 {
                    nestedTimestampListDecoded0?.append(list0Decoded0)
                }
            }
        }
        nestedTimestampList = nestedTimestampListDecoded0
        let timestampListContainer = try containerValues.decodeIfPresent([Swift.String?].self, forKey: .timestampList)
        var timestampListDecoded0:[Runtime.Date]? = nil
        if let timestampListContainer = timestampListContainer {
            timestampListDecoded0 = [Runtime.Date]()
            for timestamp0 in timestampListContainer {
                let timestamp0Formatter = Runtime.DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                guard let date0 = timestamp0Formatter.date(from: timestamp0) else {
                    throw Swift.DecodingError.dataCorrupted(Swift.DecodingError.Context(codingPath: containerValues.codingPath + [CodingKeys.timestampList], debugDescription: "date cannot be properly deserialized"))
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
        val contents = getModelFileContents("example", "MapInputOutputResponseBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
struct MapInputOutputResponseBody: Swift.Equatable {
    public let intMap: [Swift.String:Swift.Int]?
    public let structMap: [Swift.String:ExampleClientTypes.ReachableOnlyThroughMap]?
    public let enumMap: [Swift.String:ExampleClientTypes.MyEnum]?
    public let blobMap: [Swift.String:Runtime.Data]?
    public let nestedMap: [Swift.String:[Swift.String:Swift.Int]]?
    public let dateMap: [Swift.String:Runtime.Date]?
}

extension MapInputOutputResponseBody: Swift.Decodable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case blobMap
        case dateMap
        case enumMap
        case intMap
        case nestedMap
        case structMap
    }

    public init (from decoder: Swift.Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let intMapContainer = try containerValues.decodeIfPresent([Swift.String: Swift.Int?].self, forKey: .intMap)
        var intMapDecoded0: [Swift.String:Swift.Int]? = nil
        if let intMapContainer = intMapContainer {
            intMapDecoded0 = [Swift.String:Swift.Int]()
            for (key0, integer0) in intMapContainer {
                if let integer0 = integer0 {
                    intMapDecoded0?[key0] = integer0
                }
            }
        }
        intMap = intMapDecoded0
        let structMapContainer = try containerValues.decodeIfPresent([Swift.String: ExampleClientTypes.ReachableOnlyThroughMap?].self, forKey: .structMap)
        var structMapDecoded0: [Swift.String:ExampleClientTypes.ReachableOnlyThroughMap]? = nil
        if let structMapContainer = structMapContainer {
            structMapDecoded0 = [Swift.String:ExampleClientTypes.ReachableOnlyThroughMap]()
            for (key0, reachableonlythroughmap0) in structMapContainer {
                if let reachableonlythroughmap0 = reachableonlythroughmap0 {
                    structMapDecoded0?[key0] = reachableonlythroughmap0
                }
            }
        }
        structMap = structMapDecoded0
        let enumMapContainer = try containerValues.decodeIfPresent([Swift.String: ExampleClientTypes.MyEnum?].self, forKey: .enumMap)
        var enumMapDecoded0: [Swift.String:ExampleClientTypes.MyEnum]? = nil
        if let enumMapContainer = enumMapContainer {
            enumMapDecoded0 = [Swift.String:ExampleClientTypes.MyEnum]()
            for (key0, myenum0) in enumMapContainer {
                if let myenum0 = myenum0 {
                    enumMapDecoded0?[key0] = myenum0
                }
            }
        }
        enumMap = enumMapDecoded0
        let blobMapContainer = try containerValues.decodeIfPresent([Swift.String: Runtime.Data?].self, forKey: .blobMap)
        var blobMapDecoded0: [Swift.String:Runtime.Data]? = nil
        if let blobMapContainer = blobMapContainer {
            blobMapDecoded0 = [Swift.String:Runtime.Data]()
            for (key0, blob0) in blobMapContainer {
                if let blob0 = blob0 {
                    blobMapDecoded0?[key0] = blob0
                }
            }
        }
        blobMap = blobMapDecoded0
        let nestedMapContainer = try containerValues.decodeIfPresent([Swift.String: [Swift.String: Swift.Int?]?].self, forKey: .nestedMap)
        var nestedMapDecoded0: [Swift.String:[Swift.String:Swift.Int]]? = nil
        if let nestedMapContainer = nestedMapContainer {
            nestedMapDecoded0 = [Swift.String:[Swift.String:Swift.Int]]()
            for (key0, intmap0) in nestedMapContainer {
                var intmap0Decoded0: [Swift.String: Swift.Int]? = nil
                if let intmap0 = intmap0 {
                    intmap0Decoded0 = [Swift.String: Swift.Int]()
                    for (key1, integer1) in intmap0 {
                        if let integer1 = integer1 {
                            intmap0Decoded0?[key1] = integer1
                        }
                    }
                }
                nestedMapDecoded0?[key0] = intmap0Decoded0
            }
        }
        nestedMap = nestedMapDecoded0
        let dateMapContainer = try containerValues.decodeIfPresent([Swift.String: Swift.String?].self, forKey: .dateMap)
        var dateMapDecoded0: [Swift.String:Runtime.Date]? = nil
        if let dateMapContainer = dateMapContainer {
            dateMapDecoded0 = [Swift.String:Runtime.Date]()
            for (key0, timestamp0) in dateMapContainer {
                let dateMapContainerFormatter = Runtime.DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                guard let date0 = dateMapContainerFormatter.date(from: timestamp0) else {
                    throw Swift.DecodingError.dataCorrupted(Swift.DecodingError.Context(codingPath: containerValues.codingPath + [CodingKeys.dateMap], debugDescription: "date cannot be properly deserialized"))
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
            getModelFileContents("example", "NestedShapesOutputResponseBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
struct NestedShapesOutputResponseBody: Swift.Equatable {
    public let nestedListInDict: [Swift.String:[Runtime.Date]]?
    public let nestedDictInList: [[Swift.String:Swift.String]]?
    public let nestedListOfListInDict: [Swift.String:[[Swift.Int]]]?
}

extension NestedShapesOutputResponseBody: Swift.Decodable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case nestedDictInList
        case nestedListInDict
        case nestedListOfListInDict
    }

    public init (from decoder: Swift.Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let nestedListInDictContainer = try containerValues.decodeIfPresent([Swift.String: [Swift.String?]?].self, forKey: .nestedListInDict)
        var nestedListInDictDecoded0: [Swift.String:[Runtime.Date]]? = nil
        if let nestedListInDictContainer = nestedListInDictContainer {
            nestedListInDictDecoded0 = [Swift.String:[Runtime.Date]]()
            for (key0, timestamplist0) in nestedListInDictContainer {
                var timestamplist0Decoded0: [Swift.String]? = nil
                if let timestamplist0 = timestamplist0 {
                    timestamplist0Decoded0 = [Swift.String]()
                    for timestamp1 in timestamplist0 {
                        let timestamp1Formatter = Runtime.DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                        guard let date1 = timestamp1Formatter.date(from: timestamp1) else {
                            throw Swift.DecodingError.dataCorrupted(Swift.DecodingError.Context(codingPath: containerValues.codingPath + [CodingKeys.nestedListInDict], debugDescription: "date cannot be properly deserialized"))
                        }
                        timestamplist0Decoded0?.append(date1)
                    }
                }
                nestedListInDictDecoded0?[key0] = timestamplist0Decoded0
            }
        }
        nestedListInDict = nestedListInDictDecoded0
        let nestedDictInListContainer = try containerValues.decodeIfPresent([[Swift.String: Swift.String?]?].self, forKey: .nestedDictInList)
        var nestedDictInListDecoded0:[[Swift.String:Swift.String]]? = nil
        if let nestedDictInListContainer = nestedDictInListContainer {
            nestedDictInListDecoded0 = [[Swift.String:Swift.String]]()
            for map0 in nestedDictInListContainer {
                var nestedDictInListContainerDecoded0: [Swift.String: Swift.String]? = nil
                if let map0 = map0 {
                    nestedDictInListContainerDecoded0 = [Swift.String: Swift.String]()
                    for (key1, string1) in map0 {
                        if let string1 = string1 {
                            nestedDictInListContainerDecoded0?[key1] = string1
                        }
                    }
                }
                if let nestedDictInListContainerDecoded0 = nestedDictInListContainerDecoded0 {
                    nestedDictInListDecoded0?.append(nestedDictInListContainerDecoded0)
                }
            }
        }
        nestedDictInList = nestedDictInListDecoded0
        let nestedListOfListInDictContainer = try containerValues.decodeIfPresent([Swift.String: [[Swift.Int?]?]?].self, forKey: .nestedListOfListInDict)
        var nestedListOfListInDictDecoded0: [Swift.String:[[Swift.Int]]]? = nil
        if let nestedListOfListInDictContainer = nestedListOfListInDictContainer {
            nestedListOfListInDictDecoded0 = [Swift.String:[[Swift.Int]]]()
            for (key0, nestedlonglist0) in nestedListOfListInDictContainer {
                var nestedlonglist0Decoded0: [[Swift.Int]]? = nil
                if let nestedlonglist0 = nestedlonglist0 {
                    nestedlonglist0Decoded0 = [[Swift.Int]]()
                    for list1 in nestedlonglist0 {
                        var list1Decoded1: [Swift.Int]? = nil
                        if let list1 = list1 {
                            list1Decoded1 = [Swift.Int]()
                            for long2 in list1 {
                                if let long2 = long2 {
                                    list1Decoded1?.append(long2)
                                }
                            }
                        }
                        if let list1Decoded1 = list1Decoded1 {
                            nestedlonglist0Decoded0?.append(list1Decoded1)
                        }
                    }
                }
                nestedListOfListInDictDecoded0?[key0] = nestedlonglist0Decoded0
            }
        }
        nestedListOfListInDict = nestedListOfListInDictDecoded0
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
            extension ExampleClientTypes.RecursiveShapesInputOutputNested1: Swift.Codable, Runtime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case foo
                    case nested
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var encodeContainer = encoder.container(keyedBy: CodingKeys.self)
                    if let foo = foo {
                        try encodeContainer.encode(foo, forKey: .foo)
                    }
                    if let nested = nested {
                        try encodeContainer.encode(nested.value, forKey: .nested)
                    }
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let fooDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .foo)
                    foo = fooDecoded
                    let nestedDecoded = try containerValues.decodeIfPresent(Box<ExampleClientTypes.RecursiveShapesInputOutputNested2>.self, forKey: .nested)
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
            extension ExampleClientTypes.RecursiveShapesInputOutputNested2: Swift.Codable, Runtime.Reflection {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case bar
                    case recursiveMember
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var encodeContainer = encoder.container(keyedBy: CodingKeys.self)
                    if let bar = bar {
                        try encodeContainer.encode(bar, forKey: .bar)
                    }
                    if let recursiveMember = recursiveMember {
                        try encodeContainer.encode(recursiveMember, forKey: .recursiveMember)
                    }
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let barDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .bar)
                    bar = barDecoded
                    let recursiveMemberDecoded = try containerValues.decodeIfPresent(ExampleClientTypes.RecursiveShapesInputOutputNested1.self, forKey: .recursiveMember)
                    recursiveMember = recursiveMemberDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
