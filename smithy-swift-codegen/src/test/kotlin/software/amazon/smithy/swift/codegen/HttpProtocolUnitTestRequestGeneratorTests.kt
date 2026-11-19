package software.amazon.smithy.swift.codegen

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import io.kotest.matchers.string.shouldNotContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

class HttpProtocolUnitTestRequestGeneratorTests {
    var model = javaClass.classLoader.getResource("http-binding-protocol-generator-test.smithy").asSmithy()

    private fun newTestContext(): TestContext {
        val settings = model.defaultSettings()
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        return model.newTestContext()
    }

    val ctx = newTestContext()

    init {
        ctx.generator.generateProtocolUnitTests(ctx.generationCtx)
        ctx.generationCtx.delegator.flushWriters()
    }

    @Test
    fun `it creates a Swift Testing suite for request tests`() {
        val contents = getTestFileContents("example/Tests/example", "InlineDocumentRequestTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce("import Testing\n")
        contents.shouldNotContain("XCTest")
        contents.shouldNotContain("TestInitializer")
        val expectedSuite = """
@Suite
struct InlineDocumentRequestTest: SmithyTestUtil.HTTPRequestProtocolTestSuite {

    /// Serializes inline documents as part of the JSON request payload with no escaping.
    @Test
    func test_InlineDocumentInput() async throws {
"""
        contents.shouldContainOnlyOnce(expectedSuite)
        val expectedClientAndAssert = """
        let client = try await makeClient()

        let input = InlineDocumentInput(
"""
        contents.shouldContainOnlyOnce(expectedClientAndAssert)
        val expectedBodyAssert = """
        let actual = try await captureRequest { try await client.inlineDocument(input: input) }
        try await assertEqual(expected, actual, bodyContentType: .json)
    }
"""
        contents.shouldContainOnlyOnce(expectedBodyAssert)
        val expectedHelper = """
    private func makeClient(host: String = "example.com") async throws -> ExampleClient {
        let config = try await ExampleClient.ExampleClientConfig(
            awsCredentialIdentityResolver: try SmithyTestUtil.dummyIdentityResolver(),
            region: "us-west-2",
            signingRegion: "us-west-2",
            endpointResolver: example.StaticEndpointResolver(endpoint: try SmithyHTTPAPI.Endpoint(urlString: "https://\(host)")),
            idempotencyTokenGenerator: SmithyTestUtil.ProtocolTestIdempotencyTokenGenerator(),
            httpClientEngine: SmithyTestUtil.ProtocolTestClient()
        )
        return ExampleClient(config: config)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedHelper)
    }
}
