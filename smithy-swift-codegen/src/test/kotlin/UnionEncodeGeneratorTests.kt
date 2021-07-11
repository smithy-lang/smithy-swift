/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.AddOperationShapes

class UnionEncodeGeneratorTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }
    val newTestContext = newTestContext()
    init {
        newTestContext.generator.generateSerializers(newTestContext.generationCtx)
        newTestContext.generator.generateCodableConformanceForNestedTypes(newTestContext.generationCtx)
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates encodable conformance in correct file`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/JsonUnionsInput+Encodable.swift"))
    }

    @Test
    fun `it creates encodable conformance for nested structures`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/MyUnion+Codable.swift"))
    }

    @Test
    fun `it encodes a union member in an operation`() {
        val contents = getModelFileContents("example", "JsonUnionsInput+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension JsonUnionsInput: Encodable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case contents
                }

                public func encode(to encoder: Encoder) throws {
                    var encodeContainer = encoder.container(keyedBy: CodingKeys.self)
                    if let contents = contents {
                        try encodeContainer.encode(contents, forKey: .contents)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes a union with various member shape types`() {
        val contents = getModelFileContents("example", "MyUnion+Codable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension MyUnion: Codable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case blobValue
                    case booleanValue
                    case enumValue
                    case listValue
                    case mapValue
                    case numberValue
                    case sdkUnknown
                    case stringValue
                    case structureValue
                    case timestampValue
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    switch self {
                        case let .blobValue(blobValue):
                            try container.encode(blobValue.base64EncodedString(), forKey: .blobValue)
                        case let .booleanValue(booleanValue):
                            try container.encode(booleanValue, forKey: .booleanValue)
                        case let .enumValue(enumValue):
                            try container.encode(enumValue.rawValue, forKey: .enumValue)
                        case let .listValue(listValue):
                            var listValueContainer = container.nestedUnkeyedContainer(forKey: .listValue)
                            for stringlist0 in listValue {
                                try listValueContainer.encode(stringlist0)
                            }
                        case let .mapValue(mapValue):
                            var mapValueContainer = container.nestedContainer(keyedBy: Key.self, forKey: .mapValue)
                            for (dictKey0, stringmap0) in mapValue {
                                try mapValueContainer.encode(stringmap0, forKey: Key(stringValue: dictKey0))
                            }
                        case let .numberValue(numberValue):
                            try container.encode(numberValue, forKey: .numberValue)
                        case let .stringValue(stringValue):
                            try container.encode(stringValue, forKey: .stringValue)
                        case let .structureValue(structureValue):
                            try container.encode(structureValue, forKey: .structureValue)
                        case let .timestampValue(timestampValue):
                            try container.encode(timestampValue.iso8601WithoutFractionalSeconds(), forKey: .timestampValue)
                        case let .sdkUnknown(sdkUnknown):
                            try container.encode(sdkUnknown, forKey: .sdkUnknown)
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let values = try decoder.container(keyedBy: CodingKeys.self)
                    let stringValueDecoded = try values.decodeIfPresent(String.self, forKey: .stringValue)
                    if let stringValue = stringValueDecoded {
                        self = .stringValue(stringValue)
                        return
                    }
                    let booleanValueDecoded = try values.decodeIfPresent(Bool.self, forKey: .booleanValue)
                    if let booleanValue = booleanValueDecoded {
                        self = .booleanValue(booleanValue)
                        return
                    }
                    let numberValueDecoded = try values.decodeIfPresent(Int.self, forKey: .numberValue)
                    if let numberValue = numberValueDecoded {
                        self = .numberValue(numberValue)
                        return
                    }
                    let blobValueDecoded = try values.decodeIfPresent(Data.self, forKey: .blobValue)
                    if let blobValue = blobValueDecoded {
                        self = .blobValue(blobValue)
                        return
                    }
                    let timestampValueDateString = try values.decodeIfPresent(String.self, forKey: .timestampValue)
                    var timestampValueDecoded: Date? = nil
                    if let timestampValueDateString = timestampValueDateString {
                        let timestampValueFormatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
                        timestampValueDecoded = timestampValueFormatter.date(from: timestampValueDateString)
                    }
                    if let timestampValue = timestampValueDecoded {
                        self = .timestampValue(timestampValue)
                        return
                    }
                    let enumValueDecoded = try values.decodeIfPresent(FooEnum.self, forKey: .enumValue)
                    if let enumValue = enumValueDecoded {
                        self = .enumValue(enumValue)
                        return
                    }
                    let listValueContainer = try values.decodeIfPresent([String?].self, forKey: .listValue)
                    var listValueDecoded0:[String]? = nil
                    if let listValueContainer = listValueContainer {
                        listValueDecoded0 = [String]()
                        for string0 in listValueContainer {
                            if let string0 = string0 {
                                listValueDecoded0?.append(string0)
                            }
                        }
                    }
                    if let listValue = listValueDecoded0 {
                        self = .listValue(listValue)
                        return
                    }
                    let mapValueContainer = try values.decodeIfPresent([String: String?].self, forKey: .mapValue)
                    var mapValueDecoded0: [String:String]? = nil
                    if let mapValueContainer = mapValueContainer {
                        mapValueDecoded0 = [String:String]()
                        for (key0, string0) in mapValueContainer {
                            if let string0 = string0 {
                                mapValueDecoded0?[key0] = string0
                            }
                        }
                    }
                    if let mapValue = mapValueDecoded0 {
                        self = .mapValue(mapValue)
                        return
                    }
                    let structureValueDecoded = try values.decodeIfPresent(GreetingWithErrorsOutput.self, forKey: .structureValue)
                    if let structureValue = structureValueDecoded {
                        self = .structureValue(structureValue)
                        return
                    }
                    self = .sdkUnknown("")
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
