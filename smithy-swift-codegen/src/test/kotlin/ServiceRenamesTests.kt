import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ServiceRenamesTests {
    @Test
    fun `001 MyTestOperationInput uses renamed struct`() {
        val context = setupTests(listOf(
            "service-renames.smithy",
            "service-renames-namespace1.smithy",
            "service-renames-namespace2.smithy"), "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJson/models/MyTestOperationInput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct MyTestOperationInput: Equatable {
                public let bar: RenamedGreeting?

                public init (
                    bar: RenamedGreeting? = nil
                )
                {
                    self.bar = bar
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 MyTestOperationOutput uses non-renamed`() {
        val context = setupTests(listOf(
            "service-renames.smithy",
            "service-renames-namespace1.smithy",
            "service-renames-namespace2.smithy"), "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJson/models/MyTestOperationOutput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct MyTestOperationOutput: Equatable {
                public let baz: GreetingStruct?
            
                public init (
                    baz: GreetingStruct? = nil
                )
                {
                    self.baz = baz
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 Greeting Struct is not renamed`() {
        val context = setupTests(listOf(
            "service-renames.smithy",
            "service-renames-namespace1.smithy",
            "service-renames-namespace2.smithy"), "aws.protocoltests.restjson#RestJson")
        val contents = getFileContents(context.manifest, "/RestJson/models/GreetingStruct.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct GreetingStruct: Equatable {
                public let hi: String?
            
                public init (
                    hi: String? = nil
                )
                {
                    self.hi = hi
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 nested GreetingStruct is renamed to RenamedGreeting`() {
        val context = setupTests(listOf(
            "service-renames.smithy",
            "service-renames-namespace1.smithy",
            "service-renames-namespace2.smithy"), "aws.protocoltests.restjson#RestJson")
        print(listFilesFromManifest(context.manifest))
        val contents = getFileContents(context.manifest, "/RestJson/models/RenamedGreeting.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct RenamedGreeting: Equatable {
                public let salutation: String?
            
                public init (
                    salutation: String? = nil
                )
                {
                    self.salutation = salutation
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 GreetingStruct codable`() {
        val context = setupTests(listOf(
            "service-renames.smithy",
            "service-renames-namespace1.smithy",
            "service-renames-namespace2.smithy"), "aws.protocoltests.restjson#RestJson")
        print(listFilesFromManifest(context.manifest))
        val contents = getFileContents(context.manifest, "/RestJson/models/RenamedGreeting+Codable.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension RenamedGreeting: Codable, Reflection {
                enum CodingKeys: String, CodingKey {
                    case salutation
                }
            
                public func encode(to encoder: Encoder) throws {
                    var encodeContainer = encoder.container(keyedBy: CodingKeys.self)
                    if let salutation = salutation {
                        try encodeContainer.encode(salutation, forKey: .salutation)
                    }
                }
            
                public init (from decoder: Decoder) throws {
                    let containerValues = try decoder.container(keyedBy: CodingKeys.self)
                    let salutationDecoded = try containerValues.decodeIfPresent(String.self, forKey: .salutation)
                    salutation = salutationDecoded
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFiles: List<String>, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFiles, serviceShapeId) { model ->
            model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol")
        }
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}