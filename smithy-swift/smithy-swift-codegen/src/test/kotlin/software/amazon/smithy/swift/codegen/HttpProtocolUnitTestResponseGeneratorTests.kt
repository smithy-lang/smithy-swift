/*
 *
 *  * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  *
 *  * Licensed under the Apache License, Version 2.0 (the "License").
 *  * You may not use this file except in compliance with the License.
 *  * A copy of the License is located at
 *  *
 *  *  http://aws.amazon.com/apache2.0
 *  *
 *  * or in the "license" file accompanying this file. This file is distributed
 *  * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 *  * express or implied. See the License for the specific language governing
 *  * permissions and limitations under the License.
 *
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
                content: ResponseType.data(""${'"'}
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
            let actual = try SmokeTestResponse(httpResponse: httpResponse, decoder: decoder)

            let expected = SmokeTestResponse(
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

            let actual = try HttpPrefixHeadersInputOutput(httpResponse: httpResponse)

            let expected = HttpPrefixHeadersInputOutput(
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

            let actual = try HttpPrefixHeadersInputOutput(httpResponse: httpResponse)

            let expected = HttpPrefixHeadersInputOutput(
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
                content: ResponseType.data(""${'"'}
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
            let actual = try UnionInputOutput(httpResponse: httpResponse, decoder: decoder)

            let expected = UnionInputOutput(
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
}
