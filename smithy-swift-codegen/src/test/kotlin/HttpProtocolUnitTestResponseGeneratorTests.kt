/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.model.AddOperationShapes

open class HttpProtocolUnitTestResponseGeneratorTests {
    var model = javaClass.getResource("http-binding-protocol-generator-test.smithy").asSmithy()
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
    fun `it creates smoke test response test`() {
        val contents = getTestFileContents("example", "SmokeTestResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testSmokeTest() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "X-Bool": "false",
                "X-Int": "1",
                "X-String": "Hello"
            ],
            content: .data(Data(""${'"'}
            {
              "payload1": "explicit string",
              "payload2": 1,
              "payload3": {
                "member1": "test string",
                "member2": "test string 2"
              }
            }

            ""${'"'}.utf8))
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let actual: SmokeTestOutput = try await responseClosure(decoder: decoder)(httpResponse)

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

        XCTAssertEqual(expected.strHeader, actual.strHeader)
        XCTAssertEqual(expected.intHeader, actual.intHeader)
        XCTAssertEqual(expected.boolHeader, actual.boolHeader)
        XCTAssertEqual(expected.payload1, actual.payload1)
        XCTAssertEqual(expected.payload2, actual.payload2)
        XCTAssertEqual(expected.payload3, actual.payload3)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates unit test with prefixHeader and empty body`() {
        val contents = getTestFileContents("example", "HttpPrefixHeadersResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonHttpPrefixHeadersPresent() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "X-Foo": "Foo",
                "X-Foo-abc": "ABC",
                "X-Foo-xyz": "XYZ"
            ],
            content: nil
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let actual: HttpPrefixHeadersOutput = try await responseClosure(decoder: decoder)(httpResponse)

        let expected = HttpPrefixHeadersOutput(
            foo: "Foo",
            fooMap: [
                "abc": "ABC",
                "xyz": "XYZ"]

        )

        XCTAssertEqual(expected.foo, actual.foo)
        XCTAssertEqual(expected.fooMap, actual.fooMap)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates unit test with non-existent prefixHeader`() {
        val contents = getTestFileContents("example", "HttpPrefixHeadersResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonHttpPrefixHeadersAreNotPresent() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "X-Foo": "Foo"
            ],
            content: nil
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let actual: HttpPrefixHeadersOutput = try await responseClosure(decoder: decoder)(httpResponse)

        let expected = HttpPrefixHeadersOutput(
            foo: "Foo"
        )

        XCTAssertEqual(expected.foo, actual.foo)
        XCTAssertEqual(expected.fooMap, actual.fooMap)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for union shapes`() {
        val contents = getTestFileContents("example", "JsonUnionsResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonDeserializeStringUnionValue() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "Content-Type": "application/json"
            ],
            content: .data(Data(""${'"'}
            {
                "contents": {
                    "stringValue": "foo"
                }
            }
            ""${'"'}.utf8))
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let actual: JsonUnionsOutput = try await responseClosure(decoder: decoder)(httpResponse)

        let expected = JsonUnionsOutput(
            contents: MyUnion.stringvalue("foo")

        )

        XCTAssertEqual(expected.contents, actual.contents)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for recursive shapes`() {
        val contents = getTestFileContents("example", "RecursiveShapesResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonRecursiveShapes() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "Content-Type": "application/json"
            ],
            content: .data(Data(""${'"'}
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
            ""${'"'}.utf8))
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let actual: RecursiveShapesOutput = try await responseClosure(decoder: decoder)(httpResponse)

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

        XCTAssertEqual(expected.nested, actual.nested)

    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a response unit test for inline document`() {
        val contents = getTestFileContents("example", "InlineDocumentResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
class InlineDocumentResponseTest: HttpResponseTestBase {
    /// Serializes inline documents as part of the JSON response payload with no escaping.
    func testInlineDocumentOutput() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "Content-Type": "application/json"
            ],
            content: .data(Data(""${'"'}
            {
                "stringValue": "string",
                "documentValue": {
                    "foo": "bar"
                }
            }
            ""${'"'}.utf8))
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let actual: InlineDocumentOutput = try await responseClosure(decoder: decoder)(httpResponse)

        let expected = InlineDocumentOutput(
            documentValue: try decoder.decode(Document.self, from:
                ""${'"'}
                {
                    "foo": "bar"
                }
                ""${'"'}.data(using: .utf8)!)
                ,
                stringValue: "string"
            )

            XCTAssertEqual(expected.stringValue, actual.stringValue)
            XCTAssertEqual(expected.documentValue, actual.documentValue)

        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a response unit test for inline document as payload`() {
        val contents = getTestFileContents("example", "InlineDocumentAsPayloadResponseTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testInlineDocumentAsPayloadInputOutput() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: [
                "Content-Type": "application/json"
            ],
            content: .data(Data(""${'"'}
            {
                "foo": "bar"
            }
            ""${'"'}.utf8))
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let decoder = ClientRuntime.JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        let actual: InlineDocumentAsPayloadOutput = try await responseClosure(decoder: decoder)(httpResponse)

        let expected = InlineDocumentAsPayloadOutput(
            documentValue: try decoder.decode(Document.self, from:
                ""${'"'}
                {
                    "foo": "bar"
                }
                ""${'"'}.data(using: .utf8)!)

            )

            XCTAssertEqual(expected.documentValue, actual.documentValue)

        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
