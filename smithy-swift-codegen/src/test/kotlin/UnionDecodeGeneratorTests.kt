/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.AddOperationShapes

class UnionDecodeGeneratorTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
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
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/JsonUnionsOutputResponseBody+Decodable.swift"))
    }

    @Test
    fun `it creates decodable conformance for nested structures`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/MyUnion+Codable.swift"))
    }

    @Test
    fun `it decodes a union member in an operation body`() {
        val contents = getModelFileContents("example", "JsonUnionsOutputResponseBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct JsonUnionsOutputResponseBody: Equatable {
                public let contents: MyUnion?
            }

            extension JsonUnionsOutputResponseBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case contents
                }

                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let contentsDecoded = try containerValues.decodeIfPresent(MyUnion.self, forKey: .contents)
                    contents = contentsDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it decodes a union with various member shape types`() {
        val contents = getModelFileContents("example", "MyUnion+Codable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension MyUnion: Codable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case blobvalue = "blobValue"
                    case booleanvalue = "booleanValue"
                    case enumvalue = "enumValue"
                    case listvalue = "listValue"
                    case mapvalue = "mapValue"
                    case numbervalue = "numberValue"
                    case sdkUnknown
                    case stringvalue = "stringValue"
                    case structurevalue = "structureValue"
                    case timestampvalue = "timestampValue"
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    switch self {
                        case let .blobvalue(blobvalue):
                            if let blobvalue = blobvalue {
                                try container.encode(blobvalue.base64EncodedString(), forKey: .blobvalue)
                            }
                        case let .booleanvalue(booleanvalue):
                            if let booleanvalue = booleanvalue {
                                try container.encode(booleanvalue, forKey: .booleanvalue)
                            }
                        case let .enumvalue(enumvalue):
                            if let enumvalue = enumvalue {
                                try container.encode(enumvalue.rawValue, forKey: .enumvalue)
                            }
                        case let .listvalue(listvalue):
                            if let listvalue = listvalue {
                                var listvalueContainer = container.nestedUnkeyedContainer(forKey: .listvalue)
                                for stringlist0 in listvalue {
                                    try listvalueContainer.encode(stringlist0)
                                }
                            }
                        case let .mapvalue(mapvalue):
                            if let mapvalue = mapvalue {
                                var mapvalueContainer = container.nestedContainer(keyedBy: Key.self, forKey: .mapvalue)
                                for (dictKey0, stringmap0) in mapvalue {
                                    try mapvalueContainer.encode(stringmap0, forKey: Key(stringValue: dictKey0))
                                }
                            }
                        case let .numbervalue(numbervalue):
                            if let numbervalue = numbervalue {
                                try container.encode(numbervalue, forKey: .numbervalue)
                            }
                        case let .stringvalue(stringvalue):
                            if let stringvalue = stringvalue {
                                try container.encode(stringvalue, forKey: .stringvalue)
                            }
                        case let .structurevalue(structurevalue):
                            if let structurevalue = structurevalue {
                                try container.encode(structurevalue, forKey: .structurevalue)
                            }
                        case let .timestampvalue(timestampvalue):
                            if let timestampvalue = timestampvalue {
                                try container.encode(timestampvalue.iso8601WithoutFractionalSeconds(), forKey: .timestampvalue)
                            }
                        case let .sdkUnknown(sdkUnknown):
                            try container.encode(sdkUnknown, forKey: .sdkUnknown)
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let stringvalueDecoded = try values.decodeIfPresent(String.self, forKey: .stringvalue)
                    if let stringvalue = stringvalueDecoded {
                        self = .stringvalue(stringvalue)
                        return
                    }
                    let booleanvalueDecoded = try values.decodeIfPresent(Bool.self, forKey: .booleanvalue)
                    if let booleanvalue = booleanvalueDecoded {
                        self = .booleanvalue(booleanvalue)
                        return
                    }
                    let numbervalueDecoded = try values.decodeIfPresent(Int.self, forKey: .numbervalue)
                    if let numbervalue = numbervalueDecoded {
                        self = .numbervalue(numbervalue)
                        return
                    }
                    let blobvalueDecoded = try values.decodeIfPresent(Data.self, forKey: .blobvalue)
                    if let blobvalue = blobvalueDecoded {
                        self = .blobvalue(blobvalue)
                        return
                    }
                    let timestampvalueDateString = try values.decodeIfPresent(String.self, forKey: .timestampvalue)
                    var timestampvalueDecoded: Date? = nil
                    if let timestampvalueDateString = timestampvalueDateString {
                        let timestampvalueFormatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                        timestampvalueDecoded = timestampvalueFormatter.date(from: timestampvalueDateString)
                    }
                    if let timestampvalue = timestampvalueDecoded {
                        self = .timestampvalue(timestampvalue)
                        return
                    }
                    let enumvalueDecoded = try values.decodeIfPresent(FooEnum.self, forKey: .enumvalue)
                    if let enumvalue = enumvalueDecoded {
                        self = .enumvalue(enumvalue)
                        return
                    }
                    let listvalueContainer = try values.decodeIfPresent([String?].self, forKey: .listvalue)
                    var listvalueDecoded0:[String]? = nil
                    if let listvalueContainer = listvalueContainer {
                        listvalueDecoded0 = [String]()
                        for string0 in listvalueContainer {
                            if let string0 = string0 {
                                listvalueDecoded0?.append(string0)
                            }
                        }
                    }
                    if let listvalue = listvalueDecoded0 {
                        self = .listvalue(listvalue)
                        return
                    }
                    let mapvalueContainer = try values.decodeIfPresent([String: String?].self, forKey: .mapvalue)
                    var mapvalueDecoded0: [String:String]? = nil
                    if let mapvalueContainer = mapvalueContainer {
                        mapvalueDecoded0 = [String:String]()
                        for (key0, string0) in mapvalueContainer {
                            if let string0 = string0 {
                                mapvalueDecoded0?[key0] = string0
                            }
                        }
                    }
                    if let mapvalue = mapvalueDecoded0 {
                        self = .mapvalue(mapvalue)
                        return
                    }
                    let structurevalueDecoded = try values.decodeIfPresent(GreetingWithErrorsOutput.self, forKey: .structurevalue)
                    if let structurevalue = structurevalueDecoded {
                        self = .structurevalue(structurevalue)
                        return
                    }
                    self = .sdkUnknown("")
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
