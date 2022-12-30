/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class StructEncodeGenerationIsolatedTests {
    @Test
    fun `BlobInput`() {
        val context = setupTests("Isolated/BlobInput.smithy", "com.test#Example")
        Assertions.assertTrue(context.manifest.hasFile("/example/models/BlobInputInput+Encodable.swift"))
    }

    @Test
    fun `BlobInput Contents`() {
        val context = setupTests("Isolated/BlobInput.smithy", "com.test#Example")
        val contents = getModelFileContents("example", "BlobInputInput+Encodable.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
    }

    @Test
    fun `EnumInput`() {
        val testContext = setupTests("Isolated/EnumInput.smithy", "com.test#Example")
        Assertions.assertTrue(testContext.manifest.hasFile("/example/models/EnumInputInput+Encodable.swift"))
    }

    @Test
    fun `EnumInput Contents`() {
        val context = setupTests("Isolated/EnumInput.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/EnumInputInput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct EnumInputInput: Swift.Equatable {
                public var enumHeader: ExampleClientTypes.MyEnum?
                public var nestedWithEnum: ExampleClientTypes.NestedEnum?
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
    @Test
    fun `NestedNested Contents`() {
        val context = setupTests("Isolated/NestedNested-List.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/NestedNestedJsonListInputBody+Decodable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension NestedNestedJsonListInputBody: Swift.Decodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedNestedStringList
                }
            
                public init (from decoder: Swift.Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let nestedNestedStringListContainer = try containerValues.decodeIfPresent([[[Swift.String?]?]?].self, forKey: .nestedNestedStringList)
                    var nestedNestedStringListDecoded0:[[[Swift.String]]]? = nil
                    if let nestedNestedStringListContainer = nestedNestedStringListContainer {
                        nestedNestedStringListDecoded0 = [[[Swift.String]]]()
                        for list0 in nestedNestedStringListContainer {
                            var list0Decoded0: [[Swift.String]]? = nil
                            if let list0 = list0 {
                                list0Decoded0 = [[Swift.String]]()
                                for list1 in list0 {
                                    var list1Decoded1: [Swift.String]? = nil
                                    if let list1 = list1 {
                                        list1Decoded1 = [Swift.String]()
                                        for string2 in list1 {
                                            if let string2 = string2 {
                                                list1Decoded1?.append(string2)
                                            }
                                        }
                                    }
                                    if let list1Decoded1 = list1Decoded1 {
                                        list0Decoded0?.append(list1Decoded1)
                                    }
                                }
                            }
                            if let list0Decoded0 = list0Decoded0 {
                                nestedNestedStringListDecoded0?.append(list0Decoded0)
                            }
                        }
                    }
                    nestedNestedStringList = nestedNestedStringListDecoded0
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it can handle nested string lists`() {
        val context = setupTests("Isolated/NestedStringList.smithy", "com.test#Example")

        val contents = getFileContents(context.manifest, "/example/models/JsonListsInput+Encodable.swift")
        contents.shouldSyntacticSanityCheck()

        val expectedContents = """
            extension JsonListsInput: Swift.Encodable {
                enum CodingKeys: Swift.String, Swift.CodingKey {
                    case nestedStringList
                    case stringList
                    case stringSet
                }
            
                public func encode(to encoder: Swift.Encoder) throws {
                    var encodeContainer = encoder.container(keyedBy: CodingKeys.self)
                    if let nestedStringList = nestedStringList {
                        var nestedStringListContainer = encodeContainer.nestedUnkeyedContainer(forKey: .nestedStringList)
                        for stringlist0 in nestedStringList {
                            var stringlist0Container = nestedStringListContainer.nestedUnkeyedContainer()
                            for string1 in stringlist0 {
                                try stringlist0Container.encode(string1)
                            }
                        }
                    }
                    if let stringList = stringList {
                        var stringListContainer = encodeContainer.nestedUnkeyedContainer(forKey: .stringList)
                        for string0 in stringList {
                            try stringListContainer.encode(string0)
                        }
                    }
                    if let stringSet = stringSet {
                        var stringSetContainer = encodeContainer.nestedUnkeyedContainer(forKey: .stringSet)
                        for string0 in stringSet {
                            try stringSetContainer.encode(string0)
                        }
                    }
                }
            }
        """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
