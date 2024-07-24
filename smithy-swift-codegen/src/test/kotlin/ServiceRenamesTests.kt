/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class ServiceRenamesTests {
    @Test
    fun `001 MyTestOperationInput uses renamed struct`() {
        val context = setupTests(
            listOf(
                "service-renames.smithy",
                "service-renames-namespace1.smithy",
                "service-renames-namespace2.smithy"
            ),
            "aws.protocoltests.restjson#RestJson"
        )
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/MyTestOperationInput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct MyTestOperationInput {
                public var bar: ExampleClientTypes.RenamedGreeting?
            
                public init(
                    bar: ExampleClientTypes.RenamedGreeting? = nil
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
        val context = setupTests(
            listOf(
                "service-renames.smithy",
                "service-renames-namespace1.smithy",
                "service-renames-namespace2.smithy"
            ),
            "aws.protocoltests.restjson#RestJson"
        )
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/MyTestOperationOutput.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            public struct MyTestOperationOutput {
                public var baz: ExampleClientTypes.GreetingStruct?
            
                public init(
                    baz: ExampleClientTypes.GreetingStruct? = nil
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
        val context = setupTests(
            listOf(
                "service-renames.smithy",
                "service-renames-namespace1.smithy",
                "service-renames-namespace2.smithy"
            ),
            "aws.protocoltests.restjson#RestJson"
        )
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/GreetingStruct.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension ExampleClientTypes {
                public struct GreetingStruct {
                    public var hi: Swift.String?
            
                    public init(
                        hi: Swift.String? = nil
                    )
                    {
                        self.hi = hi
                    }
                }
            
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 nested GreetingStruct is renamed to RenamedGreeting`() {
        val context = setupTests(
            listOf(
                "service-renames.smithy",
                "service-renames-namespace1.smithy",
                "service-renames-namespace2.smithy"
            ),
            "aws.protocoltests.restjson#RestJson"
        )
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/RenamedGreeting.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension ExampleClientTypes {
                public struct RenamedGreeting {
                    public var salutation: Swift.String?
            
                    public init(
                        salutation: Swift.String? = nil
                    )
                    {
                        self.salutation = salutation
                    }
                }
            
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `005 GreetingStruct codable`() {
        val context = setupTests(
            listOf(
                "service-renames.smithy",
                "service-renames-namespace1.smithy",
                "service-renames-namespace2.smithy"
            ),
            "aws.protocoltests.restjson#RestJson"
        )
        val contents = getFileContents(context.manifest, "Sources/RestJson/models/RenamedGreeting+ReadWrite.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
extension RestJsonProtocolClientTypes.RenamedGreeting {

    static func write(value: RestJsonProtocolClientTypes.RenamedGreeting?, to writer: SmithyJSON.Writer) throws {
        guard let value else { return }
        try writer["salutation"].write(value.salutation)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFiles: List<String>, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(
            smithyFiles,
            serviceShapeId,
            null,
            { model -> model.defaultSettings(serviceShapeId, "RestJson", "2019-12-16", "Rest Json Protocol") },
            emptyList()
        )
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
