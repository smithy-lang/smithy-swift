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
            public struct EnumInputInput: Equatable {
                public let enumHeader: MyEnum?
                public let nestedWithEnum: NestedEnum?
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
            extension NestedNestedJsonListInputBody: Decodable {
                enum CodingKeys: String, CodingKey {
                    case nestedNestedStringList
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let nestedNestedStringListContainer = try containerValues.decodeIfPresent([[[String]?]?].self, forKey: .nestedNestedStringList)
                    var nestedNestedStringListDecoded0:[[[String]?]?]? = nil
                    if let nestedNestedStringListContainer = nestedNestedStringListContainer {
                        nestedNestedStringListDecoded0 = [[[String]?]?]()
                        for list0 in nestedNestedStringListContainer {
                            var list0Decoded0 = [[String]?]()
                            if let list0 = list0 {
                                for list1 in list0 {
                                    var list1Decoded1 = [String]()
                                    if let list1 = list1 {
                                        for string2 in list1 {
                                            list1Decoded1.append(string2)
                                        }
                                    }
                                    list0Decoded0.append(list1Decoded1)
                                }
                            }
                            nestedNestedStringListDecoded0?.append(list0Decoded0)
                        }
                    }
                    nestedNestedStringList = nestedNestedStringListDecoded0
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
