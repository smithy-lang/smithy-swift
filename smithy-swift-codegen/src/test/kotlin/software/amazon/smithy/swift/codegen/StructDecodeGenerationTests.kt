/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class StructDecodeGenerationTests : TestsBase() {

    var model = createModelFromSmithy("http-binding-protocol-generator-test.smithy")

    data class TestContext(val ctx: ProtocolGenerator.GenerationContext, val manifest: MockManifest, val generator: MockHttpProtocolGenerator)

    private fun newTestContext(): TestContext {
        val manifest = MockManifest()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example")
        val serviceShapeIdWithNamespace = "com.test#Example"
        val service = model.getShape(ShapeId.from(serviceShapeIdWithNamespace)).get().asServiceShape().get()
        val settings = SwiftSettings.from(model, buildDefaultSwiftSettingsObjectNode(serviceShapeIdWithNamespace))
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        model = RecursiveShapeBoxer.transform(model)
        val delegator = SwiftDelegator(settings, model, manifest, provider)
        val generator = MockHttpProtocolGenerator()
        val ctx = ProtocolGenerator.GenerationContext(settings, model, service, provider, listOf(), generator.protocol, delegator)
        return TestContext(ctx, manifest, generator)
    }

    val newTestContext = newTestContext()

    init {
        newTestContext.generator.generateDeserializers(newTestContext.ctx)
        newTestContext.ctx.delegator.flushWriters()
    }

    @Test
    fun `it creates decodable conformance in correct file`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/SmokeTestOutputBody+Decodable.swift"))
    }

    @Test
    fun `it creates decodable conformance for nested structures`() {
        // test that a struct member of an output operation shape also gets decodable conformance
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested+Decodable.swift"))
        // these are non-top level shapes reachable from an operation output and thus require decodable conformance
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested2+Decodable.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested3+Decodable.swift"))
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/Nested4+Decodable.swift"))
    }

    @Test
    fun `it creates smoke test request decodable conformance`() {
        val contents = getModelFileContents("example", "SmokeTestOutputBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct SmokeTestOutputBody {
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
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let payload1Decoded = try values.decodeIfPresent(String.self, forKey: .payload1)
                    payload1 = payload1Decoded
                    let payload2Decoded = try values.decodeIfPresent(Int.self, forKey: .payload2)
                    payload2 = payload2Decoded
                    let payload3Decoded = try values.decodeIfPresent(Nested.self, forKey: .payload3)
                    payload3 = payload3Decoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it decodes nested documents with aggregate shapes`() {
        val contents = getModelFileContents("example", "Nested4+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension Nested4: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case intList
                    case intMap
                    case member1
                }

                public init (from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let member1Decoded = try values.decodeIfPresent(Int.self, forKey: .member1)
                    member1 = member1Decoded
                    let intListContainer = try values.decodeIfPresent([Int].self, forKey: .intList)
                    var intListDecoded0:[Int]? = nil
                    if let intListContainer = intListContainer {
                        intListDecoded0 = [Int]()
                        for integer0 in intListContainer {
                            intListDecoded0?.append(integer0)
                        }
                    }
                    intList = intListDecoded0
                    let intMapContainer = try values.decodeIfPresent([String:Int].self, forKey: .intMap)
                    var intMapDecoded0: [String:Int]? = nil
                    if let intMapContainer = intMapContainer {
                        intMapDecoded0 = [String:Int]()
                        for (key0, integer0) in intMapContainer {
                            intMapDecoded0?[key0] = integer0
                        }
                    }
                    intMap = intMapDecoded0
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it provides decodable conformance to operation outputs with timestamps`() {
        val contents = getModelFileContents("example", "TimestampInputOutputBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
struct TimestampInputOutputBody {
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
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let normalDateString = try values.decodeIfPresent(String.self, forKey: .normal)
        var normalDecoded: Date? = nil
        if let normalDateString = normalDateString {
            let normalFormatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
            normalDecoded = normalFormatter.date(from: normalDateString)
        }
        normal = normalDecoded
        let dateTimeDateString = try values.decodeIfPresent(String.self, forKey: .dateTime)
        var dateTimeDecoded: Date? = nil
        if let dateTimeDateString = dateTimeDateString {
            let dateTimeFormatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
            dateTimeDecoded = dateTimeFormatter.date(from: dateTimeDateString)
        }
        dateTime = dateTimeDecoded
        let epochSecondsDecoded = try values.decodeIfPresent(Date.self, forKey: .epochSeconds)
        epochSeconds = epochSecondsDecoded
        let httpDateDateString = try values.decodeIfPresent(String.self, forKey: .httpDate)
        var httpDateDecoded: Date? = nil
        if let httpDateDateString = httpDateDateString {
            let httpDateFormatter = DateFormatter.rfc5322DateFormatter
            httpDateDecoded = httpDateFormatter.date(from: httpDateDateString)
        }
        httpDate = httpDateDecoded
        let nestedTimestampListContainer = try values.decodeIfPresent([[String]?].self, forKey: .nestedTimestampList)
        var nestedTimestampListDecoded0:[[Date]?]? = nil
        if let nestedTimestampListContainer = nestedTimestampListContainer {
            nestedTimestampListDecoded0 = [[Date]?]()
            for list0 in nestedTimestampListContainer {
                var list0Decoded0 = [Date]()
                if let list0 = list0 {
                    for timestamp1 in list0 {
                        let timestamp1Formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                        guard let date1 = timestamp1Formatter.date(from: timestamp1) else {
                            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: values.codingPath + [CodingKeys.nestedTimestampList], debugDescription: "date cannot be properly deserialized"))
                        }
                        list0Decoded0.append(date1)
                    }
                }
                nestedTimestampListDecoded0?.append(list0Decoded0)
            }
        }
        nestedTimestampList = nestedTimestampListDecoded0
        let timestampListContainer = try values.decodeIfPresent([String].self, forKey: .timestampList)
        var timestampListDecoded0:[Date]? = nil
        if let timestampListContainer = timestampListContainer {
            timestampListDecoded0 = [Date]()
            for timestamp0 in timestampListContainer {
                let timestamp0Formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                guard let date0 = timestamp0Formatter.date(from: timestamp0) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: values.codingPath + [CodingKeys.timestampList], debugDescription: "date cannot be properly deserialized"))
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
struct MapInputOutputBody {
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
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let intMapContainer = try values.decodeIfPresent([String:Int].self, forKey: .intMap)
        var intMapDecoded0: [String:Int]? = nil
        if let intMapContainer = intMapContainer {
            intMapDecoded0 = [String:Int]()
            for (key0, integer0) in intMapContainer {
                intMapDecoded0?[key0] = integer0
            }
        }
        intMap = intMapDecoded0
        let structMapContainer = try values.decodeIfPresent([String:ReachableOnlyThroughMap].self, forKey: .structMap)
        var structMapDecoded0: [String:ReachableOnlyThroughMap]? = nil
        if let structMapContainer = structMapContainer {
            structMapDecoded0 = [String:ReachableOnlyThroughMap]()
            for (key0, reachableonlythroughmap0) in structMapContainer {
                structMapDecoded0?[key0] = reachableonlythroughmap0
            }
        }
        structMap = structMapDecoded0
        let enumMapContainer = try values.decodeIfPresent([String:MyEnum].self, forKey: .enumMap)
        var enumMapDecoded0: [String:MyEnum]? = nil
        if let enumMapContainer = enumMapContainer {
            enumMapDecoded0 = [String:MyEnum]()
            for (key0, myenum0) in enumMapContainer {
                enumMapDecoded0?[key0] = myenum0
            }
        }
        enumMap = enumMapDecoded0
        let blobMapContainer = try values.decodeIfPresent([String:Data].self, forKey: .blobMap)
        var blobMapDecoded0: [String:Data]? = nil
        if let blobMapContainer = blobMapContainer {
            blobMapDecoded0 = [String:Data]()
            for (key0, blob0) in blobMapContainer {
                blobMapDecoded0?[key0] = blob0
            }
        }
        blobMap = blobMapDecoded0
        let nestedMapContainer = try values.decodeIfPresent([String:[String:Int]?].self, forKey: .nestedMap)
        var nestedMapDecoded0: [String:[String:Int]?]? = nil
        if let nestedMapContainer = nestedMapContainer {
            nestedMapDecoded0 = [String:[String:Int]?]()
            for (key0, intmap0) in nestedMapContainer {
                var intmap0Decoded0 = [String:Int]()
                for (key1, integer1) in intmap0 {
                    intmap0Decoded0[key1] = integer1
                }
                nestedMapDecoded0?[key0] = intmap0Decoded0
            }
        }
        nestedMap = nestedMapDecoded0
        let dateMapContainer = try values.decodeIfPresent([String:String].self, forKey: .dateMap)
        var dateMapDecoded0: [String:Date]? = nil
        if let dateMapContainer = dateMapContainer {
            dateMapDecoded0 = [String:Date]()
            for (key0, timestamp0) in dateMapContainer {
                let dateMapContainerFormatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                guard let date0 = dateMapContainerFormatter.date(from: timestamp0) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: values.codingPath + [CodingKeys.dateMap], debugDescription: "date cannot be properly deserialized"))
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
        val contents = getModelFileContents("example", "NestedShapesOutputBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
struct NestedShapesOutputBody {
    public let nestedListInDict: [String:[Date]?]?
    public let nestedDictInList: [[String:String]?]?
}

extension NestedShapesOutputBody: Decodable {
    private enum CodingKeys: String, CodingKey {
        case nestedDictInList
        case nestedListInDict
    }

    public init (from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let nestedListInDictContainer = try values.decodeIfPresent([String:[String]?].self, forKey: .nestedListInDict)
        var nestedListInDictDecoded0: [String:[Date]?]? = nil
        if let nestedListInDictContainer = nestedListInDictContainer {
            nestedListInDictDecoded0 = [String:[Date]?]()
            for (key0, timestamplist0) in nestedListInDictContainer {
                var timestamplist0Decoded0 = [Date]()
                if let timestamplist0 = timestamplist0 {
                    for timestamp1 in timestamplist0 {
                        let timestamp1Formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                        guard let date1 = timestamp1Formatter.date(from: timestamp1) else {
                            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: values.codingPath + [CodingKeys.nestedListInDict], debugDescription: "date cannot be properly deserialized"))
                        }
                        timestamplist0Decoded0.append(date1)
                    }
                }
                nestedListInDictDecoded0?[key0] = timestamplist0Decoded0
            }
        }
        nestedListInDict = nestedListInDictDecoded0
        let nestedDictInListContainer = try values.decodeIfPresent([[String:String]?].self, forKey: .nestedDictInList)
        var nestedDictInListDecoded0:[[String:String]?]? = nil
        if let nestedDictInListContainer = nestedDictInListContainer {
            nestedDictInListDecoded0 = [[String:String]?]()
            for map0 in nestedDictInListContainer {
                var nestedDictInListContainerDecoded0 = [String:String]()
                for (key1, string1) in map0 {
                    nestedDictInListContainerDecoded0[key1] = string1
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
        val contents = getModelFileContents("example", "RecursiveShapesInputOutputNested1+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
            extension RecursiveShapesInputOutputNested1: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case foo
                    case nested
                }

                public init (from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let fooDecoded = try values.decodeIfPresent(String.self, forKey: .foo)
                    foo = fooDecoded
                    let nestedDecoded = try values.decodeIfPresent(Box<RecursiveShapesInputOutputNested2>.self, forKey: .nested)
                    nested = nestedDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes one side of the recursive shape`() {
        val contents = getModelFileContents("example", "RecursiveShapesInputOutputNested2+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
            extension RecursiveShapesInputOutputNested2: Decodable {
                private enum CodingKeys: String, CodingKey {
                    case bar
                    case recursiveMember
                }

                public init (from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let barDecoded = try values.decodeIfPresent(String.self, forKey: .bar)
                    bar = barDecoded
                    let recursiveMemberDecoded = try values.decodeIfPresent(RecursiveShapesInputOutputNested1.self, forKey: .recursiveMember)
                    recursiveMember = recursiveMemberDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
