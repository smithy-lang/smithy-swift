package software.amazon.smithy.swift.codegen

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldContainOnlyOnce
import io.kotest.matchers.string.shouldNotContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.rulesengine.traits.EndpointTestsTrait
import software.amazon.smithy.swift.codegen.model.endpointParameters
import software.amazon.smithy.swift.codegen.model.expectTrait

class EndpointTestGeneratorTests {
    private val model =
        """
        namespace com.test

        use smithy.rules#endpointRuleSet
        use smithy.rules#endpointTests
        use smithy.rules#clientContextParams

        @endpointRuleSet({
            version: "1.0",
            parameters: {
                Region: { type: "string", documentation: "The region" }
            },
            rules: [
                {
                    conditions: [{ fn: "isSet", argv: [{ ref: "Region" }] }],
                    endpoint: { url: "https://{Region}.example.com" },
                    type: "endpoint"
                },
                {
                    conditions: [],
                    error: "Region must be set",
                    type: "error"
                }
            ]
        })
        @endpointTests({
            version: "1.0",
            testCases: [
                {
                    documentation: "Resolves with region",
                    params: { Region: "us-west-2" },
                    expect: { endpoint: { url: "https://us-west-2.example.com" } }
                },
                {
                    documentation: "Fails without region",
                    params: {},
                    expect: { error: "Region must be set" }
                }
            ]
        })
        @clientContextParams(
            Region: { type: "string", documentation: "The region" }
        )
        service Example {
            version: "2019-12-16"
        }
        """.trimIndent().asSmithyModel()

    private fun render(): String {
        val ctx = model.newTestContext()
        val service = ctx.generationCtx.service
        val writer = SwiftWriter("test", moduleName = "example")
        EndpointTestGenerator(
            service.expectTrait<EndpointTestsTrait>(),
            service.endpointParameters(),
            ctx.generationCtx,
        ).render(writer)
        return writer.toString()
    }

    @Test
    fun `it renders a Swift Testing suite`() {
        val contents = render()
        contents.shouldContainOnlyOnce("import Testing\n")
        contents.shouldContain("import Foundation\n")
        contents.shouldNotContain("XCT")
        val expected = """
@Suite
struct EndpointResolverTest {

    init() {
        SmithyTestUtil.TestInitializer.initialize()
    }

    /// Resolves with region
    @Test
    func testResolve1() throws {
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders an expected endpoint test`() {
        val contents = render()
        val expected = """
        let actual = try resolver.resolve(params: endpointParams)

        let properties: [String: SmithyHTTPAPI.EndpointPropertyValue] =
            [:]

        let headers = SmithyHTTPAPI.Headers()
        let expected = try SmithyHTTPAPI.Endpoint(urlString: "https://us-west-2.example.com", headers: headers, properties: properties)

        #expect(actual == expected)
    }
"""
        contents.shouldContainOnlyOnce(expected)
    }

    @Test
    fun `it renders an expected error test`() {
        val contents = render()
        val expected = """
        do {
            _ = try resolver.resolve(params: endpointParams)
            Issue.record("Expected endpoint resolution to fail")
        } catch ClientRuntime.EndpointError.unresolved(let message) {
            #expect(message == "Region must be set")
        }
    }
"""
        contents.shouldContainOnlyOnce(expected)
    }
}
