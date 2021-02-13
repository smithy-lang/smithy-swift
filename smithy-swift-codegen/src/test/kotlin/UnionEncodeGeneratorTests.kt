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
        newTestContext.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates encodable conformance in correct file`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/JsonUnionsInput+Encodable.swift"))
    }

    @Test
    fun `it creates encodable conformance for nested structures`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/MyUnion+Encodable.swift"))
    }

    @Test
    fun `it encodes a union member in an operation`() {
        val contents = getModelFileContents("example", "JsonUnionsInput+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension JsonUnionsInput: Encodable, Reflection {
                private enum CodingKeys: String, CodingKey {
                    case contents
                }

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let contents = contents {
                        try container.encode(contents, forKey: .contents)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes a union with various member shape types`() {
        val contents = getModelFileContents("example", "MyUnion+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension MyUnion: Encodable, Reflection {
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

                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    switch self {
                        case let .blobValue(blobValue):
                            if let blobValue = blobValue {
                                try container.encode(blobValue.base64EncodedString(), forKey: .blobValue)
                            }
                        case let .booleanValue(booleanValue):
                            if let booleanValue = booleanValue {
                                try container.encode(booleanValue, forKey: .booleanValue)
                            }
                        case let .enumValue(enumValue):
                            if let enumValue = enumValue {
                                try container.encode(enumValue.rawValue, forKey: .enumValue)
                            }
                        case let .listValue(listValue):
                            if let listValue = listValue {
                                var listValueContainer = container.nestedUnkeyedContainer(forKey: .listValue)
                                for stringlist0 in listValue {
                                    try listValueContainer.encode(stringlist0)
                                }
                            }
                        case let .mapValue(mapValue):
                            if let mapValue = mapValue {
                                var mapValueContainer = container.nestedContainer(keyedBy: Key.self, forKey: .mapValue)
                                for (key0, stringmap0) in mapValue {
                                    try mapValueContainer.encode(stringmap0, forKey: Key(stringValue: key0))
                                }
                            }
                        case let .numberValue(numberValue):
                            if let numberValue = numberValue {
                                try container.encode(numberValue, forKey: .numberValue)
                            }
                        case let .stringValue(stringValue):
                            if let stringValue = stringValue {
                                try container.encode(stringValue, forKey: .stringValue)
                            }
                        case let .structureValue(structureValue):
                            if let structureValue = structureValue {
                                try container.encode(structureValue, forKey: .structureValue)
                            }
                        case let .timestampValue(timestampValue):
                            if let timestampValue = timestampValue {
                                try container.encode(timestampValue.iso8601WithoutFractionalSeconds(), forKey: .timestampValue)
                            }
                        case let .sdkUnknown(sdkUnknown):
                            try container.encode(sdkUnknown, forKey: .sdkUnknown)
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
