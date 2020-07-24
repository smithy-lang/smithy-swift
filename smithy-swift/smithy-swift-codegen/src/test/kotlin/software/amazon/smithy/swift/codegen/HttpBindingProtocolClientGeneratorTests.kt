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

import io.kotest.matchers.comparables.shouldBeEqualComparingTo
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.HttpBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class MockHttpProtocolGenerator : HttpBindingProtocolGenerator() {
    override val defaultContentType: String = "application/json"
    override val protocol: ShapeId = RestJson1Trait.ID

    override fun generateProtocolUnitTests(ctx: ProtocolGenerator.GenerationContext) {}
}

// NOTE: protocol conformance is mostly handled by the protocol tests suite
class HttpBindingProtocolGeneratorTests : TestsBase() {
    val model = createModelFromSmithy("http-binding-protocol-generator-test.smithy")

    data class TestContext(val generationCtx: ProtocolGenerator.GenerationContext, val manifest: MockManifest, val generator: MockHttpProtocolGenerator)

    private fun newTestContext(): TestContext {
        val manifest = MockManifest()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example")
        val serviceShapeIdWithNamespace = "com.test#Example"
        val service = model.getShape(ShapeId.from(serviceShapeIdWithNamespace)).get().asServiceShape().get()
        val settings = SwiftSettings.from(model, buildDefaultSwiftSettingsObjectNode(serviceShapeIdWithNamespace))
        val delegator = SwiftDelegator(settings, model, manifest, provider)
        val generator = MockHttpProtocolGenerator()
        val ctx = ProtocolGenerator.GenerationContext(settings, model, service, provider, listOf(), "mockHttp", delegator)
        return TestContext(ctx, manifest, generator)
    }

    @Test
    fun `Input request confirms to HttpRequestBinding`() {
        val (ctx, manifest, generator) = newTestContext()
        generator.generateSerializers(ctx)
        ctx.delegator.flushWriters()
        val contents = getModelFileContents("Example", "SmokeTestRequest.swift", manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                "extension SmokeTestRequest: HttpRequestBinding {\n" +
                "    func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {\n" +
                "        var queryItems: [URLQueryItem] = [URLQueryItem]()\n" +
                "        var queryItem: URLQueryItem\n" +
                "        if let query1 = query1 {\n" +
                "            queryItem = URLQueryItem(name: \"Query1\", value: query1)\n" +
                "            queryItems.append(queryItem)\n" +
                "        }\n" +
                "        let endpoint = Endpoint(host: \"my-api.us-east-2.amazonaws.com\", path: path, queryItems: queryItems)\n" +
                "        var headers = HttpHeaders()\n" +
                "        headers.add(name: \"Content-Type\", value: application/json)\n" +
                "        if let header1 = header1 {\n" +
                "            headers.add(name: \"X-Header1\", value: header1)\n" +
                "        }\n" +
                "        if let header2 = header2 {\n" +
                "            headers.add(name: \"X-Header2\", value: header2)\n" +
                "        }\n" +
                "        return HttpRequest(method: method, endpoint: endpoint, headers: headers)\n" +
                "    }\n" +
                "}\n"
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `getSanitizedName generates Swifty name`() {
        val testProtocolName = "aws.rest-json-1.1"
        val sanitizedProtocolName = ProtocolGenerator.getSanitizedName(testProtocolName)
        sanitizedProtocolName.shouldBeEqualComparingTo("AWSRestJson1_1")
    }
}
