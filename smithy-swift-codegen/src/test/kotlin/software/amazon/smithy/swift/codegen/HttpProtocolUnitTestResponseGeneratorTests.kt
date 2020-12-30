/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

open class HttpProtocolUnitTestResponseGeneratorTests : TestsBase() {
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
        newTestContext.generator.generateProtocolUnitTests(newTestContext.ctx)
        newTestContext.ctx.delegator.flushWriters()
    }

    @Test
    fun `it creates smoke test response test`() {
        val contents = getTestFileContents("example", "SmokeTestResponseTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents =
            """
    func testSmokeTest() {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 200,
                headers: [
                    "X-Bool": "false",
                    "X-Int": "1",
                    "X-String": "Hello"
                ],
                content: HttpBody.data(""${'"'}
                {
                  "payload1": "explicit string",
                  "payload2": 1,
                  "payload3": {
                    "member1": "test string",
                    "member2": "test string 2"
                  }
                }

                ""${'"'}.data(using: .utf8)),
                host: host
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let actual = try SmokeTestOutput(httpResponse: httpResponse, decoder: decoder)

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

        } catch let err {
            XCTFail(err.localizedDescription)
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates unit test with prefixHeader and empty body`() {
        val contents = getTestFileContents("example", "HttpPrefixHeadersResponseTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonHttpPrefixHeadersPresent() {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 200,
                headers: [
                    "X-Foo": "Foo",
                    "X-Foo-abc": "ABC",
                    "X-Foo-xyz": "XYZ"
                ],
                host: host
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let actual = try HttpPrefixHeadersOutput(httpResponse: httpResponse)

            let expected = HttpPrefixHeadersOutput(
                foo: "Foo",
                fooMap: [
                    "abc": "ABC",
                    "xyz": "XYZ"]

            )

            XCTAssertEqual(expected.foo, actual.foo)
            XCTAssertEqual(expected.fooMap, actual.fooMap)

        } catch let err {
            XCTFail(err.localizedDescription)
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates unit test with non-existent prefixHeader`() {
        val contents = getTestFileContents("example", "HttpPrefixHeadersResponseTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonHttpPrefixHeadersAreNotPresent() {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 200,
                headers: [
                    "X-Foo": "Foo"
                ],
                host: host
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let actual = try HttpPrefixHeadersOutput(httpResponse: httpResponse)

            let expected = HttpPrefixHeadersOutput(
                foo: "Foo"
            )

            XCTAssertEqual(expected.foo, actual.foo)
            XCTAssertEqual(expected.fooMap, actual.fooMap)

        } catch let err {
            XCTFail(err.localizedDescription)
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for union shapes`() {
        val contents = getTestFileContents("example", "JsonUnionsResponseTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonDeserializeStringUnionValue() {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 200,
                headers: [
                    "Content-Type": "application/json"
                ],
                content: HttpBody.data(""${'"'}
                {
                    "contents": {
                        "stringValue": "foo"
                    }
                }
                ""${'"'}.data(using: .utf8)),
                host: host
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let actual = try JsonUnionsOutput(httpResponse: httpResponse, decoder: decoder)

            let expected = JsonUnionsOutput(
                contents: MyUnion.stringValue("foo")

            )

            XCTAssertEqual(expected.contents, actual.contents)

        } catch let err {
            XCTFail(err.localizedDescription)
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for recursive shapes`() {
        val contents = getTestFileContents("example", "RecursiveShapesResponseTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents =
            """
    func testRestJsonRecursiveShapes() {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 200,
                headers: [
                    "Content-Type": "application/json"
                ],
                content: HttpBody.data(""${'"'}
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
                ""${'"'}.data(using: .utf8)),
                host: host
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let actual = try RecursiveShapesOutput(httpResponse: httpResponse, decoder: decoder)

            let expected = RecursiveShapesOutput(
                nested: RecursiveShapesInputOutputNested1(
                    foo: "Foo1",
                    nested: Box<RecursiveShapesInputOutputNested2>(
                        value: RecursiveShapesInputOutputNested2(
                            bar: "Bar1",
                            recursiveMember: RecursiveShapesInputOutputNested1(
                                foo: "Foo2",
                                nested: Box<RecursiveShapesInputOutputNested2>(
                                    value: RecursiveShapesInputOutputNested2(
                                        bar: "Bar2"
                                    )
                                )
                            )
                        )
                    )
                )
            )

            XCTAssertEqual(expected.nested, actual.nested)

        } catch let err {
            XCTFail(err.localizedDescription)
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a response unit test for inline document`() {
        val contents = getTestFileContents("example", "InlineDocumentResponseTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
    func testInlineDocumentOutput() {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 200,
                headers: [
                    "Content-Type": "application/json"
                ],
                content: HttpBody.data(""${'"'}
                {
                    "stringValue": "string",
                    "documentValue": {
                        "foo": "bar"
                    }
                }
                ""${'"'}.data(using: .utf8)),
                host: host
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let actual = try InlineDocumentOutput(httpResponse: httpResponse, decoder: decoder)

            let expected = InlineDocumentOutput(
                documentValue: Document(
                    dictionaryLiteral:
                    (
                        "foo",
                        Document(
                            "bar")
                    )
                )
                ,
                stringValue: "string"
            )

            XCTAssertEqual(expected.stringValue, actual.stringValue)
            XCTAssertEqual(expected.documentValue, actual.documentValue)

        } catch let err {
            XCTFail(err.localizedDescription)
        }
 """
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a response unit test for inline document as payload`() {
        val contents = getTestFileContents("example", "InlineDocumentAsPayloadResponseTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
    func testInlineDocumentAsPayloadInputOutput() {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 200,
                headers: [
                    "Content-Type": "application/json"
                ],
                content: HttpBody.data(""${'"'}
                {
                    "foo": "bar"
                }
                ""${'"'}.data(using: .utf8)),
                host: host
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let actual = try InlineDocumentAsPayloadOutput(httpResponse: httpResponse, decoder: decoder)

            let expected = InlineDocumentAsPayloadOutput(
                documentValue: Document(
                    dictionaryLiteral:
                    (
                        "foo",
                        Document(
                            "bar")
                    )
                )

            )

            XCTAssertEqual(expected.documentValue, actual.documentValue)

        } catch let err {
            XCTFail(err.localizedDescription)
        }
 """
        contents.shouldContainOnlyOnce(expectedContents)
    }
}
