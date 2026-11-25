package software.amazon.smithy.swift.codegen

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import io.kotest.matchers.string.shouldNotContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

open class HttpProtocolUnitTestResponseGeneratorTests {
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
    fun `it creates a Swift Testing suite for response tests`() {
        val contents = getTestFileContents("example/Tests/example", "SmokeTestResponseTest.swift", ctx.manifest)
        contents.shouldContainOnlyOnce("import Testing\n")
        contents.shouldNotContain("XCTest")
        val expectedContents = """
@Suite
struct SmokeTestResponseTest: SmithyTestUtil.HTTPResponseProtocolTestSuite {

    /// DeSerializes a smoke test request with body, headers, query params, and prefixHeaders
    @Test
    func test_SmokeTest() async throws {
"""
        contents.shouldContainOnlyOnce(expectedContents)
        val expectedHelper = """
    private func makeClient(httpResponse: SmithyHTTPAPI.HTTPResponse, host: String = "example.com") async throws -> ExampleClient {
        let config = try await ExampleClient.ExampleClientConfig(
            awsCredentialIdentityResolver: try SmithyTestUtil.dummyIdentityResolver(),
            region: "us-west-2",
            signingRegion: "us-west-2",
            endpointResolver: example.StaticEndpointResolver(endpoint: try SmithyHTTPAPI.Endpoint(urlString: "https://\(host)")),
            retryStrategyOptions: SmithyTestUtil.ProtocolTestRetryStrategyOptions.make(),
            httpClientEngine: SmithyTestUtil.ProtocolResponseTestClient(httpResponse: httpResponse)
        )
        return ExampleClient(config: config)
    }
}
"""
        contents.shouldContainOnlyOnce(expectedHelper)
    }

    @Test
    fun `it creates smoke test response test`() {
        val contents = getTestFileContents("example/Tests/example", "SmokeTestResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func test_SmokeTest() async throws {
        let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "X-Bool": "false",
                "X-Int": "1",
                "X-String": "Hello"
            ],
            content: .data(Data(#""${'"'}
            {
              "payload1": "explicit string",
              "payload2": 1,
              "payload3": {
                "member1": "test string",
                "member2": "test string 2"
              }
            }

            ""${'"'}#.utf8))
        )

        let client = try await makeClient(httpResponse: httpResponse)

        let input = SmokeTestInput(label1: "test")

        let actual = try await client.smokeTest(input: input)

        let expected = SmokeTestOutput(
            boolHeader: false,
            intHeader: 1,
            payload1: "explicit string",
            payload2: 1,
            payload3: Nested(
                member1: "test string",
                member2: "test string 2"
            ),
            strHeader: "Hello"
        )

        #expect(actual == expected)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates unit test with prefixHeader and empty body`() {
        val contents = getTestFileContents("example/Tests/example", "HttpPrefixHeadersResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func test_RestJsonHttpPrefixHeadersPresent() async throws {
        let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "X-Foo": "Foo",
                "X-Foo-abc": "ABC",
                "X-Foo-xyz": "XYZ"
            ],
            content: nil
        )

        let client = try await makeClient(httpResponse: httpResponse)

        let input = HttpPrefixHeadersInput()

        let actual = try await client.httpPrefixHeaders(input: input)

        let expected = HttpPrefixHeadersOutput(
            foo: "Foo",
            fooMap: [
                "abc": "ABC",
                "xyz": "XYZ"]

        )

        #expect(actual == expected)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates unit test with non-existent prefixHeader`() {
        val contents = getTestFileContents("example/Tests/example", "HttpPrefixHeadersResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func test_RestJsonHttpPrefixHeadersAreNotPresent() async throws {
        let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "X-Foo": "Foo"
            ],
            content: nil
        )

        let client = try await makeClient(httpResponse: httpResponse)

        let input = HttpPrefixHeadersInput()

        let actual = try await client.httpPrefixHeaders(input: input)

        let expected = HttpPrefixHeadersOutput(
            foo: "Foo"
        )

        #expect(actual == expected)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for union shapes`() {
        val contents = getTestFileContents("example/Tests/example", "JsonUnionsResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func test_RestJsonDeserializeStringUnionValue() async throws {
        let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "Content-Type": "application/json"
            ],
            content: .data(Data(#""${'"'}
            {
                "contents": {
                    "stringValue": "foo"
                }
            }
            ""${'"'}#.utf8))
        )

        let client = try await makeClient(httpResponse: httpResponse)

        let input = JsonUnionsInput()

        let actual = try await client.jsonUnions(input: input)

        let expected = JsonUnionsOutput(
            contents: MyUnion.stringvalue("foo")

        )

        #expect(actual == expected)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for recursive shapes`() {
        val contents = getTestFileContents("example/Tests/example", "RecursiveShapesResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func test_RestJsonRecursiveShapes() async throws {
        let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "Content-Type": "application/json"
            ],
            content: .data(Data(#""${'"'}
            {
                "nested": {
                    "foo": "Foo1",
                    "nested": {
                        "bar": "Bar1",
                        "recursiveMember": {
                            "foo": "Foo2",
                            "nested": {
                                "bar": "Bar2"
                            }
                        }
                    }
                }
            }
            ""${'"'}#.utf8))
        )

        let client = try await makeClient(httpResponse: httpResponse)

        let input = RecursiveShapesInput()

        let actual = try await client.recursiveShapes(input: input)

        let expected = RecursiveShapesOutput(
            nested: RecursiveShapesInputOutputNested1(
                foo: "Foo1",
                nested: RecursiveShapesInputOutputNested2(
                    bar: "Bar1",
                    recursiveMember: RecursiveShapesInputOutputNested1(
                        foo: "Foo2",
                        nested: RecursiveShapesInputOutputNested2(
                            bar: "Bar2"
                        )
                    )
                )
            )
        )

        #expect(actual == expected)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a response unit test for inline document`() {
        val contents = getTestFileContents("example/Tests/example", "InlineDocumentResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func test_InlineDocumentOutput() async throws {
        let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "Content-Type": "application/json"
            ],
            content: .data(Data(#""${'"'}
            {
                "stringValue": "string",
                "documentValue": {
                    "foo": "bar"
                }
            }
            ""${'"'}#.utf8))
        )

        let client = try await makeClient(httpResponse: httpResponse)

        let input = InlineDocumentInput()

        let actual = try await client.inlineDocument(input: input)

        let expected = InlineDocumentOutput(
            documentValue: try Smithy.Document.make(from: Data(""${'"'}
                {
                    "foo": "bar"
                }
            ""${'"'}.utf8))
            ,
            stringValue: "string"
        )

        #expect(actual == expected)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a response unit test for inline document as payload`() {
        val contents = getTestFileContents("example/Tests/example", "InlineDocumentAsPayloadResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func test_InlineDocumentAsPayloadInputOutput() async throws {
        let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "Content-Type": "application/json"
            ],
            content: .data(Data(#""${'"'}
            {
                "foo": "bar"
            }
            ""${'"'}#.utf8))
        )

        let client = try await makeClient(httpResponse: httpResponse)

        let input = InlineDocumentAsPayloadInput()

        let actual = try await client.inlineDocumentAsPayload(input: input)

        let expected = InlineDocumentAsPayloadOutput(
            documentValue: try Smithy.Document.make(from: Data(""${'"'}
                {
                    "foo": "bar"
                }
            ""${'"'}.utf8))

        )

        #expect(actual == expected)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
