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
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates decodable conformance in correct file`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/JsonUnionsOutputBody+Decodable.swift"))
    }

    @Test
    fun `it creates decodable conformance for nested structures`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/MyUnion+Decodable.swift"))
    }

    @Test
    fun `it decodes a union member in an operation body`() {
        val contents = getModelFileContents("example", "JsonUnionsOutputBody+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            struct JsonUnionsOutputBody {
                public let contents: MyUnion?
            }

            extension JsonUnionsOutputBody: Decodable {
                private enum CodingKeys: String, CodingKey {
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
        val contents = getModelFileContents("example", "MyUnion+Decodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension MyUnion: Decodable {
                private enum CodingKeys: String, CodingKey {
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
                    let listValueContainer = try values.decodeIfPresent([String].self, forKey: .listValue)
                    var listValueDecoded0:[String]? = nil
                    if let listValueContainer = listValueContainer {
                        listValueDecoded0 = [String]()
                        for string0 in listValueContainer {
                            listValueDecoded0?.append(string0)
                        }
                    }
                    if let listValue = listValueDecoded0 {
                        self = .listValue(listValue)
                        return
                    }
                    let mapValueContainer = try values.decodeIfPresent([String:String].self, forKey: .mapValue)
                    var mapValueDecoded0: [String:String]? = nil
                    if let mapValueContainer = mapValueContainer {
                        mapValueDecoded0 = [String:String]()
                        for (key0, string0) in mapValueContainer {
                            mapValueDecoded0?[key0] = string0
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
