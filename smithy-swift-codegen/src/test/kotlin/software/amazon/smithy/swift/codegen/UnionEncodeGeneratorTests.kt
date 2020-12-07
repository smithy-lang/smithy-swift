/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class UnionEncodeGeneratorTests : TestsBase() {
    var model = createModelFromSmithy("http-binding-protocol-generator-test.smithy")

    data class TestContext(val ctx: ProtocolGenerator.GenerationContext, val manifest: MockManifest, val generator: MockHttpProtocolGenerator)

    private fun newTestContext(): TestContext {
        val manifest = MockManifest()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example")
        val serviceShapeIdWithNamespace = "com.test#Example"
        val service = model.getShape(ShapeId.from(serviceShapeIdWithNamespace)).get().asServiceShape().get()
        val settings = SwiftSettings.from(model, buildDefaultSwiftSettingsObjectNode(serviceShapeIdWithNamespace))
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        val delegator = SwiftDelegator(settings, model, manifest, provider)
        val generator = MockHttpProtocolGenerator()
        val ctx = ProtocolGenerator.GenerationContext(settings, model, service, provider, listOf(), generator.protocol, delegator)
        return TestContext(ctx, manifest, generator)
    }

    val newTestContext = newTestContext()

    init {
        newTestContext.generator.generateSerializers(newTestContext.ctx)
        newTestContext.ctx.delegator.flushWriters()
    }

    @Test
    fun `it creates encodable conformance in correct file`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/UnionInputOutput+Encodable.swift"))
    }

    @Test
    fun `it creates encodable conformance for nested structures`() {
        Assertions.assertTrue(newTestContext.manifest.hasFile("/example/models/MyUnion+Encodable.swift"))
    }

    @Test
    fun `it encodes a union member in an operation`() {
        val contents = getModelFileContents("example", "UnionInputOutput+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension UnionInputOutput: Encodable {
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
            extension MyUnion: Encodable {
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
